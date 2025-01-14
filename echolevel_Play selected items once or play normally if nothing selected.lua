--[[
 * ReaScript Name: Play selected items once or play normally if nothing selected
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
I needed this for a mouse button binding I use on my Logitech G-502.
It's inspired by Xenakios' 'Play selected items once', but when nothing
is selected it falls back to normal indefinite playback from playhead position.
--]]

-- Function to get the range of selected items
local function get_selection_range()
    local count = reaper.CountSelectedMediaItems(0)
    if count == 0 then return nil, nil end

    local min_start, max_end = math.huge, -math.huge
    for i = 0, count - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local item_length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        local item_end = item_start + item_length

        if item_start < min_start then min_start = item_start end
        if item_end > max_end then max_end = item_end end
    end

    return min_start, max_end
end

-- Main logic
local function main()
    local play_state = reaper.GetPlayState()

    -- If transport is playing (play_state = 1), stop playback
    if play_state & 1 == 1 then
        reaper.Main_OnCommand(40044, 0) -- Transport: Stop
    else
        local selected_count = reaper.CountSelectedMediaItems(0)

        if selected_count == 1 then
            -- One item selected: Play the item and stop after it ends
            local item = reaper.GetSelectedMediaItem(0, 0)
            local item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            local item_length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
            local item_end = item_start + item_length

            reaper.SetEditCurPos(item_start, false, false) -- Set play cursor to item start
            reaper.Main_OnCommand(40044, 0) -- Transport: Play

            -- Monitor playback and stop after the item ends
            local function stop_after_item()
                if reaper.GetPlayPosition() >= item_end then
                    reaper.Main_OnCommand(40044, 0) -- Transport: Stop
                    reaper.SetEditCurPos(item_start, false, false) -- Reset cursor position
                    return
                end
                reaper.defer(stop_after_item) -- Keep monitoring
            end
            stop_after_item()

        elseif selected_count > 1 then
            -- Multiple items selected: Play the range and stop after it ends
            local start_pos, end_pos = get_selection_range()
            if start_pos and end_pos then
                reaper.SetEditCurPos(start_pos, false, false) -- Set play cursor to range start
                reaper.Main_OnCommand(40044, 0) -- Transport: Play

                -- Monitor playback and stop after the range ends
                local function stop_after_range()
                    if reaper.GetPlayPosition() >= end_pos then
                        reaper.Main_OnCommand(40044, 0) -- Transport: Stop
                        reaper.SetEditCurPos(start_pos, false, false) -- Reset cursor position
                        return
                    end
                    reaper.defer(stop_after_range) -- Keep monitoring
                end
                stop_after_range()
            end

        else
            -- No items selected: Start playback normally from the current playhead position
            reaper.Main_OnCommand(40044, 0) -- Transport: Play
        end
    end
end

-- Run the script
main()

