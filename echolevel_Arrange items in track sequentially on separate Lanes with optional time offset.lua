--[[
 * ReaScript Name: Arrange items in track sequentially on separate Lanes with optional time offset
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
Arrange all items in the selected track sequentially in time on separate Lanes with optional time offset and start/end fades.
The first item is excluded from the offset time, which can be positive or negative. The first and last items are also excluded
from fadein and fadeout respectively. Each item's position is calculated as "the end time of the previous item plus (or minus)
the offset". I hope that all makes sense! 
--]]

-- Prompt user for the time offset in seconds
local retval, userInput = reaper.GetUserInputs("Set Time Offset", 2, "Offset (seconds):,Fade edges:", "0,0")

-- If the user cancelled, exit the script
if not retval then return end

-- Convert the input to a number
local offset, fadeEdges = userInput:match("([^,]+),([^,]+)")  -- Extract the values
offset = tonumber(offset)
fadedur = tonumber(fadeEdges)

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
reaper.SetMediaTrackInfo_Value(track, "I_FREEMODE", 2)

-- Set the number of fixed lanes to match the number of items
reaper.SetMediaTrackInfo_Value(track, "I_NUMFIXEDLANES", item_count)

-- Iterate through the items and arrange them
local previous_end_position = nil
for i = 0, item_count - 1 do
    local item = reaper.GetTrackMediaItem(track, i)

    if item then

        -- Set fades to half of the offset 
        if offset < 0 then
        
          local fade_duration = math.abs(offset * 0.5)
        
          if i == 0 then
            -- Only apply a fadeout to the first item
            reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", fadedur)
          elseif i == item_count-1 then
            -- Only apply a fadein to the last item
            reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", fadedur)
          else
            -- Apply both to everything else
            reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", fadedur)
            reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", fadedur)
          end
        
        end
    
        local position = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

        if i > 0 and previous_end_position ~= nil then
            -- Set position based on the end of the previous item plus the offset
            position = previous_end_position + offset
            reaper.SetMediaItemInfo_Value(item, "D_POSITION", position)
        end

        -- Move the item to its own lane
        reaper.SetMediaItemInfo_Value(item, "I_FIXEDLANE", i)
        
        local item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local item_end = item_start + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        
        
        
        

        -- Update previous_end_position to the current item's end time
        previous_end_position = position + length
    end
end


-- Update the arrangement and end the undo block
reaper.UpdateArrange()
reaper.Undo_EndBlock("Arrange items in separate lanes with offset", -1)

