--[[
 * ReaScript Name: Arrange items in track sequentially with offset
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
After writing 'Arrange items in track sequentially on separate Lanes with optional time offset',
I discovered the Reaper option 'Offset overlapping media items vertically' which means that this
much simpler script is probably more use than the last.
But we still do need to set the fades manually, because they only happen natively when the items 
are dragged, not when they're programmatically repositioned.

To be clear: for this script to work, you need to enable Options->Offset overlapping media items vertically
--]]

-- Prompt user for the time offset in seconds
local retval, userInput = reaper.GetUserInputs("Set Time Offset", 1, "Offset (seconds):", "0")

-- If the user cancelled, exit the script
if not retval then return end

-- Convert the input to a number
local offset = tonumber(userInput)

if not offset then
    reaper.ShowMessageBox("Please enter a valid number for the offset.", "Invalid Input", 0)
    return
end

-- Begin an undo block
reaper.Undo_BeginBlock()

-- Get the selected track
local track = reaper.GetSelectedTrack(0, 0)
if not track then
    reaper.ShowMessageBox("Please select a track first.", "No Track Selected", 0)
    return
end

-- Get the number of items on the track
local item_count = reaper.CountTrackMediaItems(track)
if item_count == 0 then
    reaper.ShowMessageBox("The selected track has no items.", "No Items Found", 0)
    return
end

-- Enable fixed item lanes on the track
--reaper.SetMediaTrackInfo_Value(track, "I_FREEMODE", 2)

-- Set the number of fixed lanes to match the number of items
--reaper.SetMediaTrackInfo_Value(track, "I_NUMFIXEDLANES", item_count)

-- Iterate through the items and arrange them
local previous_end_position = nil
for i = 0, item_count - 1 do
    local item = reaper.GetTrackMediaItem(track, i)

    if item then

        
        local position = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

        if i > 0 and previous_end_position ~= nil then
            -- Set position based on the end of the previous item plus the offset
            position = previous_end_position + offset
            reaper.SetMediaItemInfo_Value(item, "D_POSITION", position)
        end

        -- Move the item to its own lane
        --reaper.SetMediaItemInfo_Value(item, "I_FIXEDLANE", i)
        
        local item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local item_end = item_start + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        
        -- Update previous_end_position to the current item's end time
        previous_end_position = position + length
        
        -- Set fades to the difference between 
        if offset < 0 then
        
          local fade_duration = math.abs(offset)
        
          if i == 0 then
            -- Only apply a fadeout to the first item
            reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", fade_duration)
          elseif i == item_count-1 then
            -- Only apply a fadein to the last item
            reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", fade_duration)
          else
            -- Apply both to everything else
            reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", fade_duration)
            reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", fade_duration)
          end
        
        end
        
    end
end


-- Update the arrangement and end the undo block
reaper.UpdateArrange()
reaper.Undo_EndBlock("Arrange items in separate lanes with offset", -1)

