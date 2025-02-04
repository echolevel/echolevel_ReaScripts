--[[
Reaper script to explode a multichannel BWF item to separate child tracks, muting the 
original item, preserving the metadata, and appending the new item names with Sound Devices
recorder track name and 'circled' status from Sound Devices iXML tags
]]

function explode_multichannel_item()
    reaper.Undo_BeginBlock()
    
    local item = reaper.GetSelectedMediaItem(0, 0)
    if not item then
        reaper.ShowMessageBox("No item selected!", "Error", 0)
        return
    end
    
    local take = reaper.GetActiveTake(item)
    if not take or not reaper.TakeIsMIDI(take) then
        local source = reaper.GetMediaItemTake_Source(take)
        local pcm_source = reaper.GetMediaSourceParent(source) or source
        
        local num_channels = reaper.GetMediaSourceNumChannels(pcm_source)
        if num_channels < 2 then
            reaper.ShowMessageBox("Item is not multichannel!", "Error", 0)
            return
        end
        
        local track = reaper.GetMediaItemTrack(item)
        local track_idx = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER") - 1
        local position = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        local snap_offset = reaper.GetMediaItemInfo_Value(item, "D_SNAPOFFSET")
        local fade_in = reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN")
        local fade_out = reaper.GetMediaItemInfo_Value(item, "D_FADEOUTLEN")
        local take_name = reaper.GetTakeName(take)
        local item_name = reaper.ULT_GetMediaItemNote(item)
        
        -- Mute the original item
        reaper.SetMediaItemInfo_Value(item, "B_MUTE", 1)
        
        -- Make the original track a folder parent
        reaper.SetMediaTrackInfo_Value(track, "I_FOLDERDEPTH", 1)
        
        -- Create new tracks inside the folder
        for ch = 0, num_channels - 1 do
            reaper.InsertTrackAtIndex(track_idx + ch + 1, true)
            local new_track = reaper.GetTrack(0, track_idx + ch + 1)
            reaper.SetMediaTrackInfo_Value(new_track, "I_FOLDERDEPTH", 0) -- Keep it inside the folder
            
            local new_item = reaper.AddMediaItemToTrack(new_track)
            reaper.SetMediaItemInfo_Value(new_item, "D_POSITION", position)
            reaper.SetMediaItemInfo_Value(new_item, "D_LENGTH", length)
            reaper.SetMediaItemInfo_Value(new_item, "D_SNAPOFFSET", snap_offset)
            reaper.SetMediaItemInfo_Value(new_item, "D_FADEINLEN", fade_in)
            reaper.SetMediaItemInfo_Value(new_item, "D_FADEOUTLEN", fade_out)
            
            local new_take = reaper.AddTakeToMediaItem(new_item)
            reaper.SetMediaItemTake_Source(new_take, source)
            
            reaper.SetMediaItemTakeInfo_Value(new_take, "I_CHANMODE", ch + 2) -- Set channel mode to mono (0-based index + 2 for mono)
            
            metaVal = "IXML:TRACK_LIST:TRACK:NAME"
            if ch > 0 then
              numStr = tostring(ch+1)
              metaVal = metaVal .. ':' .. numStr
            end
            
            retValue, trackNameBuf = reaper.GetMediaFileMetadata(source, metaVal)
            retValue, circledBuf = reaper.GetMediaFileMetadata(source, "IXML:CIRCLED")
            
            reaper.GetSetMediaItemTakeInfo_String(new_take, "P_NAME", take_name .. ' TRACK:' .. trackNameBuf .. ' CIRCLED:' .. circledBuf, true)
            
            
            reaper.ULT_SetMediaItemNote(new_item, item_name)
            
            reaper.SetMediaItemSelected(new_item, true)
        end
        
        -- Close the folder after the last added track
        reaper.SetMediaTrackInfo_Value(reaper.GetTrack(0, track_idx + num_channels), "I_FOLDERDEPTH", -1)
    end
    
    reaper.Undo_EndBlock("Explode multichannel item to mono items", -1)
    reaper.UpdateArrange()
end

explode_multichannel_item()

