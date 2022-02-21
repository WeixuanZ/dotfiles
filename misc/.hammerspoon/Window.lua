-- Helper functions for window managment

-- Based on hs-config MIT (c) Mik Trpcic
-- https://github.com/mtrpcic/hs-config/blob/master/Spoons/WindowGridSnapping.spoon/init.lua


local Window = {}

function Window.getActiveWindow()
    return hs.application.frontmostApplication():focusedWindow()
end


function Window.ensureOnScreen(win)
    if not win:frame():inside(win:screen():frame()) then
        win:moveToScreen(win:screen(), true, true)
    end
end


function Window.snap(win)
    hs.grid.snap(win)
    Window.ensureOnScreen(win)
end


function Window.snapCurrent()
    Window.snap(hs.window.focusedWindow())
end


function Window.snapAll()
    hs.fnutils.map(hs.window.visibleWindows(), Window.snap)
end


function Window.SnapOnLaunchCallback(appName, event)
    if event == hs.application.watcher.launched then
        local app = hs.appfinder.appFromName(appName)
        -- protect against unexpected restarting windows
        if app == nil then
            return
        end
        hs.fnutils.map(app:allWindows(), Window.snap)
    end
end


Window.transformCell = {
    left = function(cell, gridSize)
        if cell.x == 0 then
            cell.w = cell.w - 1
        else
            cell.x = cell.x - 1
            cell.w = cell.w + 1
        end
        return cell
    end,
    down = function(cell, gridSize)
        if cell.y + cell.h == gridSize.h then
            cell.h = cell.h - 1
            cell.y = cell.y + 1
        else
            cell.h = cell.h + 1
        end
        return cell
    end,
    up = function(cell, gridSize)
        if cell.y == 0 then
            cell.h = cell.h - 1
        else
            cell.y = cell.y - 1
            cell.h = cell.h + 1
        end
        return cell
    end,
    right = function(cell, gridSize)
        if cell.x + cell.w == gridSize.w then
            cell.w = cell.w - 1
            cell.x = cell.x + 1
        else
            cell.w = cell.w + 1
        end
        return cell
    end
}


function Window.getFlexOperator(direction)
    return function()
        local win = Window.getActiveWindow()
        local cell = hs.grid.get(win)
        local gridSize = hs.grid.getGrid(win:screen())

        hs.grid.set(
            win,
            Window.transformCell[direction](cell, gridSize),
            win:screen()
            )
    end
end


function Window.gatherWindows()
    local screen = hs.screen.mainScreen()
    local screenFrame = screen:fullFrame()
    local wins = hs.window.visibleWindows()
    for i,win in ipairs(wins) do
        local frame = win:frame()
        if not frame:inside(screenFrame) then
            win:moveToScreen(screen, true, true)
        end
    end
end


return Window
