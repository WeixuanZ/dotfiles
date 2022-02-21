-- vim: foldlevel=0

hs.loadSpoon("SpoonInstall")

-- Vim Config {{{

local VimMode = hs.loadSpoon("VimMode")
local vim = VimMode:new()

-- Configure apps you do *not* want Vim mode enabled in
-- For example, you don't want this plugin overriding your control of Terminal
-- vim
vim
    :disableForApp('Code')
    :disableForApp('PyCharm')
    :disableForApp('WebStorm')
    :disableForApp('zoom.us')
    :disableForApp('iTerm')
    :disableForApp('iTerm2')
    :disableForApp('Terminal')

-- If you want the screen to dim (a la Flux) when you enter normal mode
-- flip this to true.
vim:shouldDimScreenInNormalMode(false)

-- If you want to show an on-screen alert when you enter normal mode, set
-- this to true
vim:shouldShowAlertInNormalMode(true)

-- You can configure your on-screen alert font
vim:setAlertFont("Courier New")

-- Enter normal mode by typing a key sequence
-- vim:enterWithSequence('jk')

-- if you want to bind a single key to entering vim, remove the
-- :enterWithSequence('jk') line above and uncomment the bindHotKeys line
-- below:
--
-- To customize the hot key you want, see the mods and key parameters at:
--   https://www.hammerspoon.org/docs/hs.hotkey.html#bind
--
vim:bindHotKeys({ enter = { {'ctrl'}, ';' } })

-- }}}


-- Window Management {{{
-- Based on https://github.com/ztomer/.hammerspoon/blob/master/init.lua
-- and https://github.com/S1ngS1ng/HammerSpoon/blob/master/window-management.lua

local Window = require "Window"

-- hotkey mash
local mash           = {"cmd"}
local mash_secondary = {"cmd", "ctrl"}
hs.window.animationDuration = 0
hs.hints.style = "vimperator"


local function initializeGrid()
    -- init grid
    hs.grid.setMargins('0, 0')

    screens = {}
    screenArr = {}
    local screenwatcher = hs.screen.watcher.new(function()
        screens = hs.screen.allScreens()
    end)
    screenwatcher:start()

    -- construct list of screens
    indexDiff = 0
    for index=1,#hs.screen.allScreens() do
        local xIndex,yIndex = hs.screen.allScreens()[index]:position()
        screenArr[xIndex] = hs.screen.allScreens()[index]
    end

    -- find lowest screen index, save to indexDiff if negative
    hs.fnutils.each(screenArr, function(e)
        local currentIndex = hs.fnutils.indexOf(screenArr, e)
        if currentIndex < 0 and currentIndex < indexDiff then
            indexDiff = currentIndex
        end
    end)

    -- set screen grid depending on resolution
    for _index,screen in pairs(hs.screen.allScreens()) do
        if screen:frame().w / screen:frame().h > 2 then
            -- 6 * 2 for ultra wide screen
            hs.grid.setGrid('6 * 2', screen)
        else
            if screen:frame().w < screen:frame().h then
                -- 2 * 3 for vertically aligned screen
                hs.grid.setGrid('2 * 3', screen)
            else
                -- 2 * 2 for normal screen
                hs.grid.setGrid('2 * 2', screen)
            end
        end
    end
end


local function initializeWindowBindings()
    -- global operations
    hs.hotkey.bind(mash_secondary, ';', Window.snapCurrent)
    hs.hotkey.bind(mash_secondary, "'", Window.snapAll)
    hs.hotkey.bind(mash_secondary, 'M', hs.grid.maximizeWindow)

    -- change focus
    hs.hotkey.bind(mash, 'H', function() hs.window.focusedWindow():focusWindowWest() end)
    hs.hotkey.bind(mash, 'L', function() hs.window.focusedWindow():focusWindowEast() end)
    hs.hotkey.bind(mash, 'K', function() hs.window.focusedWindow():focusWindowNorth() end)
    hs.hotkey.bind(mash, 'J', function() hs.window.focusedWindow():focusWindowSouth() end)

    -- adjust grid size
    hs.hotkey.bind(mash_secondary, '=', function() hs.grid.adjustWidth( 1) end)
    hs.hotkey.bind(mash_secondary, '-', function() hs.grid.adjustWidth(-1) end)
    hs.hotkey.bind(mash_secondary, ']', function() hs.grid.adjustHeight( 1) end)
    hs.hotkey.bind(mash_secondary, '[', function() hs.grid.adjustHeight(-1) end)

    -- multi monitor
    hs.hotkey.bind(mash_secondary, 'N', function() hs.window.focusedWindow():moveOneScreenEast(true) end)
    hs.hotkey.bind(mash_secondary, 'P', function() hs.window.focusedWindow():moveOneScreenWest(true) end)

    -- move windows
    hs.hotkey.bind(mash_secondary, 'H', hs.grid.pushWindowLeft)
    hs.hotkey.bind(mash_secondary, 'J', hs.grid.pushWindowDown)
    hs.hotkey.bind(mash_secondary, 'K', hs.grid.pushWindowUp)
    hs.hotkey.bind(mash_secondary, 'L', hs.grid.pushWindowRight)
    hs.hotkey.bind(mash_secondary, 'G', Window.gatherWindows)

    -- resize windows
    hs.hotkey.bind(mash_secondary, 'Y', Window.getFlexOperator('left'))
    hs.hotkey.bind(mash_secondary, 'U', Window.getFlexOperator('down'))
    hs.hotkey.bind(mash_secondary, 'I', Window.getFlexOperator('up'))
    hs.hotkey.bind(mash_secondary, 'O', Window.getFlexOperator('right'))

    -- window hints
    hs.hotkey.bind(mash, '.', hs.hints.windowHints)
    hs.hotkey.bind(mash_secondary, '.', hs.grid.toggleShow)
end

initializeGrid()
initializeWindowBindings()

-- hs.application.watcher.new(Window.snapOnLaunchCallback):start()

-- }}}


-- Config Reloading {{{

function reloadConfig(files)
    doReload = false
    for _,file in pairs(files) do
        if file:sub(-4) == ".lua" then
            doReload = true
        end
    end
    if doReload then
        hs.reload()
    end
end
myWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/dotfiles/misc/.hammerspoon/", reloadConfig):start()
hs.notify.new({title="Hammerspoon", informativeText="Config loaded"}):send()

-- }}}

