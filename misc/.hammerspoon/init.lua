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

-- init grid
hs.grid.MARGINX     = 0
hs.grid.MARGINY     = 0
hs.grid.GRIDWIDTH   = 7
hs.grid.GRIDHEIGHT  = 3

-- disable animation
hs.window.animationDuration = 0

-- hotkey mash
local mash           = {"cmd"}
local mash_secondary = {"cmd", "ctrl"}

-- snap all newly launched windows
local function auto_tile(appName, event)
    if event == hs.application.watcher.launched then
        local app = hs.appfinder.appFromName(appName)
        -- protect against unexpected restarting windows
        if app == nil then
            return
        end
        hs.fnutils.map(app:allWindows(), hs.grid.snap)
    end
end

-- Moves all windows outside the view into the curent view
local function rescue_windows()
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

local function init_wm_binding()
    -- global operations
    hs.hotkey.bind(mash_secondary, ';', function() hs.grid.snap(hs.window.focusedWindow()) end)
    hs.hotkey.bind(mash_secondary, "'", function() hs.fnutils.map(hs.window.visibleWindows(), hs.grid.snap) end)

    -- adjust grid size
    hs.hotkey.bind(mash_secondary, '=', function() hs.grid.adjustWidth( 1) end)
    hs.hotkey.bind(mash_secondary, '-', function() hs.grid.adjustWidth(-1) end)
    hs.hotkey.bind(mash_secondary, ']', function() hs.grid.adjustHeight( 1) end)
    hs.hotkey.bind(mash_secondary, '[', function() hs.grid.adjustHeight(-1) end)

    -- change focus
    hs.hotkey.bind(mash, 'H', function() hs.window.focusedWindow():focusWindowWest() end)
    hs.hotkey.bind(mash, 'L', function() hs.window.focusedWindow():focusWindowEast() end)
    hs.hotkey.bind(mash, 'K', function() hs.window.focusedWindow():focusWindowNorth() end)
    hs.hotkey.bind(mash, 'J', function() hs.window.focusedWindow():focusWindowSouth() end)

    hs.hotkey.bind(mash_secondary, 'M', hs.grid.maximizeWindow)

    -- multi monitor
    hs.hotkey.bind(mash_secondary, 'N', hs.grid.pushWindowNextScreen)
    hs.hotkey.bind(mash_secondary, 'P', hs.grid.pushWindowPrevScreen)

    -- move windows
    hs.hotkey.bind(mash_secondary, 'H', hs.grid.pushWindowLeft)
    hs.hotkey.bind(mash_secondary, 'J', hs.grid.pushWindowDown)
    hs.hotkey.bind(mash_secondary, 'K', hs.grid.pushWindowUp)
    hs.hotkey.bind(mash_secondary, 'L', hs.grid.pushWindowRight)
    hs.hotkey.bind(mash_secondary, 'R', function() rescue_windows() end)

    -- resize windows
    hs.hotkey.bind(mash_secondary, 'Y', hs.grid.resizeWindowThinner)
    hs.hotkey.bind(mash_secondary, 'U', hs.grid.resizeWindowTaller)
    hs.hotkey.bind(mash_secondary, 'I', hs.grid.resizeWindowShorter)
    hs.hotkey.bind(mash_secondary, 'O', hs.grid.resizeWindowWider)

    -- Window Hints
    -- hs.hotkey.bind(mash_secondary, '.', function() hs.hints.windowHints(hs.window.allWindows()) end)
    hs.hotkey.bind(mash, '.', hs.hints.windowHints)
end

init_wm_binding()
-- hs.application.watcher.new(auto_tile):start()

-- appNameWatch = hs.application.watcher.new(function(appName, eventType, app)
    -- hs.alert.show(hs.application.frontmostApplication():name())
-- end):start()

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

