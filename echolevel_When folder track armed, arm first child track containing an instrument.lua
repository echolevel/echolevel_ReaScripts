--[[
When folder track is armed, instead arm the first child track which contains an instrument.
I use this in conjunction with 'auto arm on select' for previewing instruments in complex
orchestral templates (assuming each instrument midi track has its own plugin instance)
]]

last_click_time = 0
last_selected_track = nil
double_click_threshold = 0.3 -- 300ms

function has_VSTi(track)
    local fx_count = reaper.TrackFX_GetCount(track)
    for i = 0, fx_count - 1 do
        if reaper.TrackFX_GetIOSize(track, i) > 0 then -- VSTi plugins have nonzero input count
            return true
        end
    end
    return false
end

function get_first_child_with_VSTi(folder_track)
    local track_idx = reaper.GetMediaTrackInfo_Value(folder_track, "IP_TRACKNUMBER")
    local total_tracks = reaper.CountTracks(0)

    for i = track_idx, total_tracks - 1 do
        local track = reaper.GetTrack(0, i)
        if not track then break end
        
        local depth = reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH")
        if depth < 0 then break end -- Reached end of folder

        if has_VSTi(track) then
            return track
        end
    end
    return nil
end

function check_double_click()
    local track = reaper.GetSelectedTrack(0, 0) -- Get first selected track
    if track then
        local folder_depth = reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH")
        local current_time = reaper.time_precise()

        if folder_depth > 0 then -- It's a folder track
            if track == last_selected_track and (current_time - last_click_time) < double_click_threshold then
                -- Detected a double-click, select first child with VSTi
                local child_track = get_first_child_with_VSTi(track)
                if child_track then
                    reaper.SetOnlyTrackSelected(child_track)
                end
            end
            last_click_time = current_time
            last_selected_track = track
        end
    end

    reaper.defer(check_double_click) -- Keep running
end

reaper.defer(check_double_click)

