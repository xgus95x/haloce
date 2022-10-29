
api_version = "1.10.0.0"
scrim_mode = 1
timelimit = 1200
no_lead = "ON"

function OnScriptLoad()
	register_callback(cb['EVENT_COMMAND'], "OnEventCommand")
	register_callback(cb['EVENT_CHAT'], "OnPlayerChat")
	rcon_command_failed_message = sig_scan("B8????????E8??000000A1????????55")
    if rcon_command_failed_message ~= 0 then
        message_address = read_dword(rcon_command_failed_message + 1)
        safe_write(true)
        write_byte(message_address,0)
        safe_write(false)
    end
end

function OnScriptUnload() end

function OnEventCommand(PlayerIndex, Command, Enviroment, Password)
	local allowed = true
	local t = tokenizestring(string.lower(string.gsub(Command, '"', "")), " ")
	local cheat = is_cheat_command(t[1])
	if cheat and scrim_mode == 1 then
		if get_var(PlayerIndex, "$hash") ~= "f6550479b60e51ed4725d6e33d4b7dfa" then
			allowed = false
			xprint(PlayerIndex, "Scrim Mode is ON! You can't execute this command now!", Enviroment)
		end
	end
	if get_var(PlayerIndex, "$lvl") ~= "-1" or tonumber(Enviroment) == 0 then
		if t[1] == "scrim_mode" then
			command_scrim_mode(PlayerIndex, string.lower(string.gsub(Command, [["]], "")), Enviroment)
			allowed = false
		elseif t[1] == "no_lead" then
			if tostring(t[2]) == "1" or tostring(t[2]) == "true" then
				no_lead = "ON"
			else
				no_lead = "OFF"
			end
		end
	end
	return allowed
end

function OnPlayerChat(PlayerIndex, Message)
	local allowed = true
	if Message == nil then allowed = false end
	local Command = chat_command(Message)
	if Command ~= nil then
		local t = tokenizestring(string.lower(Command), " ")
		if t[1] == "info" then
			command_info(PlayerIndex)
			allowed = false
		elseif t[1] == "scrim_mode" then
			command_scrim_mode(PlayerIndex, Command, 2)
			allowed = false
		end
	end
	return allowed
end

function command_info(User)
	local sv_name = string.gsub(get_var(1, "$svname"), '', "")
	local map = get_var(1, "$map")
	local gametype = get_var(1, "$gt")
	local secs, mins, hrs = gettimestamp(Time())
	local timeleft = mins.." minutes "..secs.." seconds"
	local players = (get_var(1, "$pn").."/"..read_byte(0x006C7B45))
	say(User, "SAPP Version 10.2.1 CE")
	say(User, "Server Name: "..sv_name)
	say(User, string.format("Map: %s | GameType: %s", map, gametype))
	say(User, string.format("Time Left: %s | Players %s", timeleft, players))
	if scrim_mode == 1 then
		say(User, "Scrim Mode: ON | NoLead: "..no_lead.." | Anticheat: OFF")
	else
		say(User, "Scrim Mode: OFF | NoLead: "..no_lead.." | Anticheat: OFF")
	end
end

function command_scrim_mode(PlayerIndex, Command, Enviroment)
	local t = tokenizestring(string.lower(Command), " ")
	if get_var(PlayerIndex, "$lvl") ~= "-1" then
		if t[2] ~= nil then
			if tonumber(t[2]) == 1 then
				say_all("The admin has ENABLED the Scrim Mode!")
				scrim_mode = 1
			else
				say_all("The admin has DISABLED the Scrim Mode!")
				scrim_mode = 0
			end
		else
			if scrim_mode == 1 then
				xprint(PlayerIndex, "Scrim Mode: enabled", Enviroment)
			else
				xprint(PlayerIndex, "Scrim Mode: disabled", Enviroment)
			end
		end
	else
		xprint(PlayerIndex, "You do not have the rights to execute this command!", Enviroment)
	end
end

function chat_command(Message)
	local fixed = nil
	if string.sub(Message,0,1) == '/' then
		fixed = string.gsub(Message, '/', "")
	elseif string.sub(Message,0,1) == '\\' then
		fixed = string.gsub(Message, '\\', "")
	end
	return fixed
end

function is_cheat_command(Command)
	for i = 1,#commands do
		if Command == commands[i] then
			return true
		end
	end
	return false
end

function xprint(PlayerIndex, Message, Enviroment)
	if tonumber(PlayerIndex) ~= 0 then
		if tonumber(Enviroment) ~= 2 then
			rprint(PlayerIndex, Message)
		else
			say(PlayerIndex, compatable_message(Message))
		end
	else
		cprint(compatable_message(Message), 14)
	end
end

function compatable_message(Message)
	local Message = string.gsub(tostring(Message), "|t", "	")
	return Message -- So we dont get other useless shit from gsub
end

function Time()
	local gametype_base = read_dword(read_dword(sig_scan("A1????????8B480C894D00") + 0x1))
	local reset_tick = read_dword(read_dword(sig_scan("8B510C6A018915????????E8????????83C404") + 7))
	local time_passed = (read_dword(gametype_base + 0xC) - reset_tick) / 30
	local time_left = timelimit - tonumber(time_passed)
	return time_left
end

function gettimestamp(seconds)
	if seconds > 60 then
		minutes = math.floor(seconds / 60)
		seconds = seconds - (minutes * 60)
		if seconds < 10 then
			seconds = "0"..tostring(seconds)
		else
			seconds = seconds
		end
		if minutes > 60 then
			hours = math.floor(minutes / 60)
			minutes = minutes - (hours * 60)
		else
			hours = 0
		end
	else
		if seconds < 10 then
			seconds = "0"..tostring(seconds)
		else
			seconds = seconds
		end
		minutes = 0
		hours = 0
	end
	return math.floor(seconds), math.floor(minutes), hours
end

function tokenizestring(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t={} ; i=1
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		t[i] = str
		i = i + 1
	end
	return t
end

-- Cheat Commands
commands = {}
commands[1] = "afk"
commands[2] = "ammo"
commands[3] = "quit"
commands[4] = "ayy lmao"
commands[5] = "assists"
commands[6] = "battery"
commands[7] = "block_all_objects"
commands[8] = "block_all_vehicles"
commands[9] = "block_object"
commands[10] = "block_tc"
commands[11] = "boost"
commands[12] = "camo"
commands[13] = "color"
commands[14] = "coord"
commands[15] = "d"
commands[16] = "deaths"
commands[17] = "disable_all_objects"
commands[18] = "disable_all_vehicles"
commands[19] = "disable_backtap"
commands[20] = "disable_object"
commands[21] = "gamespeed"
commands[22] = "god"
commands[23] = "gravity"
commands[24] = "hill_timer"
commands[25] = "hp"
commands[26] = "inf"
commands[27] = "k"
commands[28] = "kill"
commands[39] = "kills"
commands[30] = "lag"
commands[31] = "lua"
commands[32] = "lua_call"
commands[33] = "lua_load"
commands[34] = "lua_unload"
commands[35] = "m"
commands[36] = "mag"
commands[37] = "nades"
commands[38] = "s"
commands[39] = "score"
commands[40] = "scorelimit"
commands[41] = "sh"
commands[42] = "spawn"
commands[43] = "t"
commands[44] = "team_score"
commands[45] = "timelimit"
commands[46] = "tp"
commands[47] = "venter"
commands[48] = "vexit"
commands[49] = "wadd"
commands[50] = "wdel"
commands[51] = "wdrop"
commands[52] = "yeye"
commands[53] = "zombies"
