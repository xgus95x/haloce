-- Full reset by Kavawuvi ^v^

api_version = "1.10.0.0"

tick_counter_address = nil
sv_map_reset_tick_address = nil
last_sv_map = 0

function OnScriptLoad()
    local check_timer_sig = sig_scan("8B68??8BC599F7FB")
    if check_timer_sig == 0 then return end
    
    register_callback(cb['EVENT_TICK'],"OnTick")
    local tick_counter_sig = sig_scan("8B2D????????807D0000C644240600")
    if tick_counter_sig == 0 then return end
    local sv_map_reset_tick_sig = sig_scan("8B510C6A018915????????E8????????83C404")
    if sv_map_reset_tick_sig == 0 then return end
    tick_counter_address = read_dword(read_dword(tick_counter_sig + 2)) + 0xC
    sv_map_reset_tick_address = read_dword(sv_map_reset_tick_sig + 7)
    
    safe_write(true)
    write_byte(check_timer_sig + 2, 0xC + 28)
    safe_write(false)
    
    write_dword(tick_counter_address + 28, read_dword(tick_counter_address))
end
function OnScriptUnload() 
    local check_timer_sig = sig_scan("8B68??8BC599F7FB")
    if check_timer_sig == 0 then return end
    safe_write(true)
    write_byte(check_timer_sig + 2, 0xC)
    safe_write(false)
end

function OnTick()
    local s = read_dword(sv_map_reset_tick_address)
    local t = read_dword(tick_counter_address)
    if s ~= last_sv_map or t == 0 then
        last_sv_map = s
        write_dword(tick_counter_address + 28,0)
    else
        write_dword(tick_counter_address + 28,read_dword(tick_counter_address + 28) + 1)
    end
end