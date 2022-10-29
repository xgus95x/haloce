-- Team HUD by Kavawuvi ^v^

-- This is the whitelist for weapons (if you only want to show power weapons)
--      Format: ["tag path"] = true,
-- If it's empty, all weapons will be shown.
ALLOWED_WEAPONS = {
    ["weapons\\rocket launcher\\rocket launcher"] = true,
    ["weapons\\sniper rifle\\sniper rifle"] = true,
    ["weapons\\plasma_cannon\\plasma_cannon"] = true,
    ["weapons\\flag\\flag"] = true
}

-- Show nade pickup notifications?
SHOW_NADES = false

-- These are custom weapon names, followed by the correct article to use
--     Use "a" for weapons that start with a consonant
--     Use "an" for weapon names that start with a vowel
--     Use "the" if the weapon is important and there's only one that can be
--         picked up
--     If the weapon tag isn't found, the file name (not including directories)
--         will be used.
WEAPON_NAMES = {
    ["weapons\\assault rifle\\assault rifle"] = {"assault rifle","an"},
    ["weapons\\ball\\ball"] = {"ball","the"},
    ["weapons\\flag\\flag"] = {"flag","the"},
    ["weapons\\flamethrower\\flamethrower"] = {"flamethrower","a"},
    ["weapons\\gravity rifle\\gravity rifle"] = {"gravity rifle","a"},
    ["weapons\\needler\\mp_needler"] = {"needler","a"},
    ["weapons\\needler\\needler"] = {"needler","a"},
    ["weapons\\pistol\\pistol"] = {"pistol","a"},
    ["weapons\\plasma pistol\\plasma pistol"] = {"plasma pistol","a"},
    ["weapons\\plasma rifle\\plasma rifle"] = {"plasma rifle","a"},
    ["weapons\\plasma_cannon\\plasma_cannon"] = {"fuel rod gun","a"},
    ["weapons\\rocket launcher\\rocket launcher"] = {"rocket launcher","a"},
    ["weapons\\shotgun\\shotgun"] = {"shotgun","a"},
    ["weapons\\sniper rifle\\sniper rifle"] = {"sniper rifle","a"}
}

-- Maximum message lines to show? The maximum number possible is 15, but
--      numbers too high will cover up too much of the screen.
MAX_MESSAGE_LINES = 0

api_version = "1.10.0.0"

tick_counter_address = nil
sv_map_reset_tick_address = nil
game_in_progress = false
messages = {}
old_stats = {}

function OnScriptLoad()
    register_callback(cb['EVENT_GAME_START'],"OnStart")
    register_callback(cb['EVENT_GAME_END'],"OnEnd")
    register_callback(cb['EVENT_TICK'],"OnTick")
    register_callback(cb['EVENT_WEAPON_PICKUP'],"OnPickup")
    register_callback(cb['EVENT_SPAWN'],"OnSpawn")
    local tick_counter_sig = sig_scan("8B2D????????807D0000C644240600")
    if(tick_counter_sig == 0) then return end
    local sv_map_reset_tick_sig = sig_scan("8B510C6A018915????????E8????????83C404")
    if(sv_map_reset_tick_sig == 0) then return end
    tick_counter_address = read_dword(read_dword(tick_counter_sig + 2)) + 0xC
    sv_map_reset_tick_address = read_dword(sv_map_reset_tick_sig + 7)
    timer(1000 / 3,"ShowStats")
    OnStart()
end
function OnScriptUnload() end
function OnStart()
    messages = {}
    old_stats = {}
    game_in_progress = true
end
function OnEnd()
    game_in_progress = false
end
floor = math.floor

function SetMessage(PlayerIndex,Message,Time)
    messages[tonumber(PlayerIndex)] = {
        ["message"] = Message,
        ["time"] = tonumber(Time),
        ["player"] = tonumber(PlayerIndex)
    }
end

local gmatch = string.gmatch

function OnSpawn(PlayerIndex)
    messages[PlayerIndex] = nil
end

function TagFile(Tag)
    local t = ""
    local t_stuff = gmatch(Tag,"[a-z,A-Z,0-9, ,_]+")
    for i in t_stuff do
        t = i
    end
    return t
end

function WeaponAllowed(Tag)
    return (ALLOWED_WEAPONS == nil or ALLOWED_WEAPONS == {} or ALLOWED_WEAPONS[Tag])
end

function OnPickup(PlayerIndex,Slot,Type)
    if Type == "1" then
        local dyn = get_dynamic_player(PlayerIndex)
        if dyn ~= 0 then
            local weapon = get_object_memory(read_dword(dyn + 0x2F8 + (tonumber(Slot) - 1) * 4))
            if weapon ~= 0 then
                local weapon_tag = read_string(read_dword(lookup_tag(read_dword(weapon)) + 0x10))
                local weapon
                if WEAPON_NAMES[weapon_tag] ~= nil then
                    weapon = WEAPON_NAMES[weapon_tag][2] .. " " .. WEAPON_NAMES[weapon_tag][1]
                else
                    weapon = TagFile(weapon_tag)
                end
                if WeaponAllowed(weapon_tag) then SetMessage(PlayerIndex,"picked up " .. weapon,90) end
            end
        end
    elseif Type == "2" and SHOW_NADES then
        if Slot == "1" then SetMessage(PlayerIndex,"picked up a fragmentation grenade",90)
        elseif Slot == "2" then SetMessage(PlayerIndex,"picked up a plasma grenade",90)
        end
    end
end

function OnTick()
    if get_var(1,"$ffa") == "1" then return end
    for i = 1,16 do
        if messages[i] ~= nil then
            messages[i].time = messages[i].time - 1
            if messages[i].time <= 0 or player_alive(i) ~= true then
                messages[i] = nil
            end
        end
        local dyn = get_dynamic_player(i)
        if dyn ~= 0 then
            local camo = read_word(get_player(i) + 0x68)
            local health = read_float(dyn + 0xE0)
            local shield = read_float(dyn + 0xE4)

            if old_stats[i] == nil then
                old_stats[i] = {
                    ["camo"] = camo,
                    ["shield"] = shield,
                    ["health"] = health,
                    ["ammo"] = {
                        [1] = {0,0,0xFFFFFFFF},
                        [2] = {0,0,0xFFFFFFFF},
                        [3] = {0,0,0xFFFFFFFF},
                        [4] = {0,0,0xFFFFFFFF}
                    }
                }
                for v = 1,4 do
                    local oid = read_dword(dyn + 0x2F8 + (v - 1) * 4)
                    local obj = get_object_memory(oid)
                    if obj ~= 0 then
                        old_stats[i].ammo[v] = {read_word(obj + 0x2B6),read_word(obj + 0x2C6),oid}
                    end
                end
            end

            for v = 1,4 do
                local oid = read_dword(dyn + 0x2F8 + (v - 1) * 4)
                local obj = get_object_memory(oid)
                if obj ~= 0 then
                    local ammo = {read_word(obj + 0x2B6),read_word(obj + 0x2C6)}
                    if old_stats[i].ammo[v][3] == oid and (ammo[1] > old_stats[i].ammo[v][1] or ammo[2] > old_stats[i].ammo[v][2]) then
                        local tag_path = read_string(read_dword(lookup_tag(read_dword(obj)) + 0x10))
                        local name_t = WEAPON_NAMES[tag_path]
                        local name
                        if name_t == nil then name = TagFile(tag_path) else name = name_t[1] end
                        if WeaponAllowed(tag_path) then SetMessage(i,"picked up ammo for " .. name,60) end
                    end
                    old_stats[i].ammo[v] = ammo
                    old_stats[i].ammo[v][3] = oid
                else
                    old_stats[i].ammo[v] = {0,0,0xFFFFFFFF}
                end
            end

            if camo > old_stats[i].camo and camo > 300 then
                SetMessage(i,"picked up an active camouflage", 90)
            end

            if shield == 3 or shield > 1.0 and old_stats[i].shield <= 1.0 then
                SetMessage(i,"picked up an overshield", 90)
            end

            if old_stats[i].health < 1.0 and health == 1.0 then
                SetMessage(i,"picked up a health pack", 90)
            end

            old_stats[i].camo = camo
            old_stats[i].shield = shield
            old_stats[i].health = health
        else
            old_stats[i] = nil
        end
    end
end
function ShowStats()
    if game_in_progress == false then return true end
    local ffa = get_var(1,"$ffa") == "1"
    local stats = {}

    if ffa == false then
        for i = 1,16 do
            if player_present(i) then
                stats[i] = {["state"] = "online"}
                stats[i].team = get_var(i,"$team")
                stats[i].name = get_var(i,"$name")
                local dyn = get_dynamic_player(i)
                if dyn == 0 then
                    if tonumber(get_var(i,"$deaths")) > 0 then
                        stats[i].alive = "dead"
                    else
                        stats[i].alive = "not spawned"
                    end
                    local pl = get_player(i)
                    local respawning_time_s = read_dword(pl + 0x2C) / 30
                    local respawning_time = floor(read_dword(pl + 0x2C) / 30)
                    if respawning_time == 1 then
                        stats[i].respawn_time = "respawns in " .. respawning_time .. " second"
                    elseif respawning_time_s == 0 then
                        stats[i].respawn_time = "is respawning... (waiting for space to clear)"
                    else
                        stats[i].respawn_time = "respawns in " .. respawning_time .. " seconds"
                    end
                else
                    stats[i].alive = "alive"
                end
            else
                stats[i] = {["state"] = "offline"}
            end
        end
    end
    local time_elapsed = floor((read_dword(tick_counter_address) - read_dword(sv_map_reset_tick_address)) / 30)
    local minutes = floor(time_elapsed / 60)
    if minutes < 10 then
        minutes = "0" .. minutes
    end
    local timer = minutes .. ":"
    local seconds = time_elapsed % 60
    if seconds < 10 then
        timer = timer .. "0"
    end
    timer = timer .. seconds
    for i = 1,16 do
        if player_present(i) then
			for x = 0,8 do
				rprint(i,"|n")
			end
            local team = get_var(i,"$team")
            local messages_to_show = {}
            local respawn_messages = {}

            if ffa == false then
                for k = 1,16 do
                    if k ~= i then
                        if stats[k].team == team then
                            if stats[k].alive == "alive" and messages[k] ~= nil then
                                messages_to_show[#messages_to_show + 1] = stats[k].name .. " " .. messages[k].message
                            elseif stats[k].alive == "dead" then
                                respawn_messages[#respawn_messages + 1] = stats[k].name .. " " .. stats[k].respawn_time
                            end
                        end
                    end
                end
            end

            local lines_left = 18
            local lines_sent = 0

            local required_lines = #respawn_messages + #messages_to_show
            if required_lines > MAX_MESSAGE_LINES then
                required_lines = MAX_MESSAGE_LINES
            end
            for x = 1,lines_left - required_lines do
                rprint(i,"|n")
            end

            local last_message = "|r" .. timer .. "  "

            for k,v in pairs(messages_to_show) do
                if lines_sent == MAX_MESSAGE_LINES then break end
                lines_sent = lines_sent + 1

                if lines_sent == MAX_MESSAGE_LINES or lines_sent == required_lines then
                    last_message = "|c" .. v .. last_message
                else
                    rprint(i,"|c" .. v)
                end
            end
            for k,v in pairs(respawn_messages) do
                if lines_sent == MAX_MESSAGE_LINES then break end
                lines_sent = lines_sent + 1
                if lines_sent == MAX_MESSAGE_LINES or lines_sent == required_lines then
                    last_message = "|c" .. v .. last_message
                else
                    rprint(i,"|c" .. v)
                end
            end

            rprint(i,last_message)
        end
    end
    return true
end
