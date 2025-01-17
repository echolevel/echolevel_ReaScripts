--[[
If one or more items are selected, duplicate them. If no items are selected, duplicate the current track.
I map this to Ctrl+D.
]]

function duplicate_items_or_tracks()
    reaper.Undo_BeginBlock() -- Start an undo block

    -- Count selected items and tracks
    local item_count = reaper.CountSelectedMediaItems(0)
    local track_count = reaper.CountSelectedTracks(0)

    if item_count > 0 then
        -- Duplicate selected items
        for i = 0, item_count - 1 do
            local item = reaper.GetSelectedMediaItem(0, i)
            local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            local length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
            local track = reaper.GetMediaItem_Track(item)

            local new_item = reaper.AddMediaItemToTrack(track)
            reaper.SetMediaItemInfo_Value(new_item, "D_POSITION", pos + length)
            reaper.SetMediaItemInfo_Value(new_item, "D_LENGTH", length)

            -- Copy item takes
            local take_count = reaper.CountTakes(item)
            for t = 0, take_count - 1 do
                local take = reaper.GetMediaItemTake(item, t)
                local source = reaper.GetMediaItemTake_Source(take)
                reaper.AddTakeToMediaItem(new_item)
                local new_take = reaper.GetMediaItemTake(new_item, t)
                reaper.SetMediaItemTake_Source(new_take, source)
            end
        end
    elseif track_count > 0 then
        -- Duplicate selected tracks
        for i = 0, track_count - 1 do
            local track = reaper.GetSelectedTrack(0, i)
            reaper.SetOnlyTrackSelected(track, true)
            reaper.Main_OnCommand(40062, 0) -- Duplicate tracks
        end
    else
        reaper.ShowMessageBox("No items or tracks are selected.", "Duplicate Script", 0)
    end

    reaper.Undo_EndBlock("Duplicate items or tracks", -1) -- End undo block
end

-- Execute the function
duplicate_items_or_tracks()

