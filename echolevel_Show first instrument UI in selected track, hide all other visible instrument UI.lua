--[[
Close all visible VSTi/VST3i UI panels and then open the first VSTi/VST3i panel on the selected track.
I map this using Options->Preferences->Mouse Modifiers to LMB double-click on the track control panel.
]]

-- Reaper script to close all visible VSTi/VST3i UI panels and open the first VSTi/VST3i panel on the selected track

function get_first_vst_instrument(track)
    -- Loop through all FX on the track
    for fx = 0, reaper.TrackFX_GetCount(track) - 1 do
        local _, fx_name = reaper.TrackFX_GetFXName(track, fx, "")
        -- Check if the FX name contains "VSTi" or "VST3i" (indicating it's an instrument)
        if fx_name:match("VSTi") or fx_name:match("VST3i") then
            return fx
        end
    end
    return -1 -- No instrument found
end

function close_all_vst_instruments()
    -- Loop through all tracks
    for i = 0, reaper.CountTracks(0) - 1 do
        local track = reaper.GetTrack(0, i)
        -- Loop through all FX on the track
        for fx = 0, reaper.TrackFX_GetCount(track) - 1 do
            local _, fx_name = reaper.TrackFX_GetFXName(track, fx, "")
            if fx_name:match("VSTi") or fx_name:match("VST3i") then
                reaper.TrackFX_Show(track, fx, 2) -- Hide the FX editor
            end
        end
    end
end

function open_first_vst_instrument_on_selected_track()
    local track = reaper.GetSelectedTrack(0, 0) -- Get the first selected track
    if not track then return end -- Exit if no track is selected

    local vst_index = get_first_vst_instrument(track)
    if vst_index >= 0 then
        reaper.TrackFX_Show(track, vst_index, 3) -- Show the FX editor
    end
end

-- Main execution
close_all_vst_instruments()
open_first_vst_instrument_on_selected_track()

