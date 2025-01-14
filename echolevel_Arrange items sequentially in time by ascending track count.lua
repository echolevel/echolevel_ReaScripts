--[[
 * ReaScript Name: Arrange items sequentially in time by ascending track count
 * Author: echolevel
 * Licence: GPL v3
 * REAPER: 7.29
 * Extensions: None
 * Version: 1.0
--]]
 
--[[
 * Changelog:
 * v1.0 (2025-01-14)
   + Initial Release
--]]

--[[
Arrange all selected items sequentially in time by track count, ascending, where tracks 
containing multiple items have the intervals between their items retained. From the second
track onwards, each track's first item will be positioned at the end of the previous track's
last item, plus an optional offset which may be positive or negative. An optional fade
duration specifies fadein times on each track's first item and fadeout times on each track's
last item. No fades are applied on those items' inner edges or to items on multi-item tracks
which are between the first and last items. Phew! Does that all make sense? Basically if you
drag a load of wavs into a project, each on its own track, this script lets you assemble
a continuous sequential mix very quickly.
--]]

function main()
    local numSelectedItems = reaper.CountSelectedMediaItems(0)
    
    if numSelectedItems < 1 then
        reaper.ShowMessageBox("No items selected!", "Error", 0)
        return
    end

    -- Prompt user for the time offset in seconds
    local retval, userInput = reaper.GetUserInputs("Set Time Offset", 2, "Offset (seconds):,Fade edges:", "0,0")
    
    -- If the user cancelled, exit the script
    if not retval then return end
    
    -- Convert the input to a number
    local offset, fadeEdges = userInput:match("([^,]+),([^,]+)")  -- Extract the values
    user_offset_sec = tonumber(offset)
    fadedur = tonumber(fadeEdges)

    -- Group items by track
    local trackItems = {}
    for i = 0, numSelectedItems - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local track = reaper.GetMediaItem_Track(item)
        local trackIndex = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
        
        if not trackItems[trackIndex] then
            trackItems[trackIndex] = {items = {}, track = track}
        end
        local itemStart = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local itemLength = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        table.insert(trackItems[trackIndex].items, {item = item, start = itemStart, length = itemLength})
    end

    -- Sort tracks by track index
    local sortedTracks = {}
    for trackIndex, trackData in pairs(trackItems) do
        table.insert(sortedTracks, {trackIndex = trackIndex, data = trackData})
    end
    table.sort(sortedTracks, function(a, b) return a.trackIndex < b.trackIndex end)
    
    -- Calculate and adjust item positions
    local currentTime = nil
    for _, trackEntry in ipairs(sortedTracks) do
        local trackData = trackEntry.data
        local items = trackData.items

        -- Skip empty tracks
        if #items == 0 then
            goto continue
        end

        -- Sort items by their start time
        table.sort(items, function(a, b) return a.start < b.start end)
        
        -- Calculate Track Start Time and Track Final Time
        local trackStartTime = items[1].start
        local trackFinalTime = items[#items].start + items[#items].length
        
        -- Add fadeins to the first item on each track, fadeouts to the last, with exceptions
        reaper.SetMediaItemInfo_Value(items[1].item, "D_FADEINLEN", fadedur)
        reaper.SetMediaItemInfo_Value(items[#items].item, "D_FADEOUTLEN", fadedur)
        
        -- Determine the new starting position for the track
        if not currentTime then
            currentTime = trackStartTime
        end
        
        -- Adjust positions of all items on the track while preserving intervals
        for _, itemData in ipairs(items) do
            local item = itemData.item
            local offset = itemData.start - trackStartTime 
            reaper.SetMediaItemInfo_Value(item, "D_POSITION", currentTime + offset)
        end
        
        -- Update currentTime for the next track
        currentTime = currentTime + (trackFinalTime - trackStartTime)  + user_offset_sec

        ::continue::
    end

    -- Update REAPER to reflect changes
    reaper.UpdateArrange()
end

-- Run the script within REAPER's undo block
reaper.Undo_BeginBlock()
main()
reaper.Undo_EndBlock("Align selected items across tracks with preserved intervals, ignoring empty tracks", -1)

