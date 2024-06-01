--[[
    GD50
    Legend of Zelda

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

require 'src/config/Dependencies'

function love.load()
    math.randomseed(os.time())
    love.window.setTitle('Legend of Zelda')
    love.graphics.setDefaultFilter('nearest', 'nearest')

    Push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        vsync = true,
        resizable = true
    })

    love.graphics.setFont(GFonts['small'])

    GStateMachine = StateMachine {
        ['start'] = function() return StartState() end,
        ['play'] = function() return PlayState() end,
        ['game-over'] = function() return GameOverState() end
    }
    GStateMachine:change('start')

    GSounds['music']:setLooping(true)
    GSounds['music']:play()

    love.keyboard.keysPressed = {}
end

function love.resize(w, h)
    Push:resize(w, h)
end

function love.keypressed(key)
    love.keyboard.keysPressed[key] = true
end

function love.keyboard.wasPressed(key)
    return love.keyboard.keysPressed[key]
end

function love.update(dt)
    Timer.update(dt)
    GStateMachine:update(dt)

    love.keyboard.keysPressed = {}
end

function love.draw()
    Push:start()
    GStateMachine:render()
    Push:finish()
end
