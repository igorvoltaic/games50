--[[
    GD50 2018
    Flappy Bird Remake James was here 2018

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    A mobile game by Dong Nguyen that went viral in 2013, utilizing a very simple
    but effective gameplay mechanic of avoiding pipes indefinitely by just tapping
    the screen, making the player's bird avatar flap its wings and move upwards slightly.
    A variant of popular games like "Helicopter Game" that floated around the internet
    for years prior. Illustrates some of the most basic procedural generation of game
    levels possible as by having pipes stick out of the ground by varying amounts, acting
    as an infinitely generated obstacle course for the player.
]]

-- push is a library that will allow us to draw our game at a virtual
-- resolution, instead of however large our window is; used to provide
-- a more retro aesthetic
--
-- https://github.com/Ulydev/push
Push = require 'push'

-- the "Class" library we're using will allow us to represent anything in
-- our game as code, rather than keeping track of many disparate variables and
-- methods
--
-- https://github.com/vrld/hump/blob/master/class.lua
Class = require 'class'

-- a basic StateMachine class which will allow us to transition to and from
-- game states smoothly and avoid monolithic code in one file
require 'StateMachine'

-- all states our StateMachine can transition between
require 'states/BaseState'
require 'states/CountdownState'
require 'states/PlayState'
require 'states/ScoreState'
require 'states/TitleScreenState'

require 'Bird'
require 'Pipe'
require 'PipePair'

-- physical screen dimensions
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

-- virtual resolution dimensions
VIRTUAL_WIDTH = 512
VIRTUAL_HEIGHT = 288

local background = love.graphics.newImage('images/background.png')
local backgroundScroll = 0

local ground = love.graphics.newImage('images/ground.png')
local groundScroll = 0

local BACKGROUND_SCROLL_SPEED = 30
local GROUND_SCROLL_SPEED = 60

local BACKGROUND_LOOPING_POINT = 413

function love.load()
    -- initialize our nearest-neighbor filter
    love.graphics.setDefaultFilter('nearest', 'nearest')

    -- seed the RNG
    math.randomseed(os.time())

    -- app window title
    love.window.setTitle('Fifty Bird')

    -- initialize our nice-looking retro text fonts
    SmallFont = love.graphics.newFont('fonts/font.ttf', 8)
    MediumFont = love.graphics.newFont('fonts/flappy.ttf', 14)
    FlappyFont = love.graphics.newFont('fonts/flappy.ttf', 28)
    HugeFont = love.graphics.newFont('fonts/flappy.ttf', 56)
    love.graphics.setFont(FlappyFont)

    -- initialize our table of sounds
    Sounds = {
        ['jump'] = love.audio.newSource('sounds/jump.wav', 'static'),
        ['explosion'] = love.audio.newSource('sounds/explosion.wav', 'static'),
        ['hurt'] = love.audio.newSource('sounds/hurt.wav', 'static'),
        ['score'] = love.audio.newSource('sounds/score.wav', 'static'),

        -- https://freesound.org/people/xsgianni/sounds/388079/
        ['music'] = love.audio.newSource('sounds/marios_way.mp3', 'static')
    }

    -- kick off music
    Sounds['music']:setLooping(true)

    -- initialize our virtual resolution
    Push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        vsync = true,
        fullscreen = false,
        resizable = true
    })

    -- initialize state machine with all state-returning functions
    GStateMachine = StateMachine {
        ['title'] = function() return TitleScreenState() end,
        ['countdown'] = function() return CountdownState() end,
        ['play'] = function() return PlayState() end,
        ['score'] = function() return ScoreState() end,
    }
    GStateMachine:change('title')

    -- initialize input table
    love.keyboard.keysPressed = {}

    -- initialize mouse input table
    love.mouse.buttonsPressed = {}
end

function love.resize(w, h)
    Push:resize(w, h)
end

function love.keypressed(key)
    -- add to our table of keys pressed this frame
    love.keyboard.keysPressed[key] = true

    if key == 'escape' then
        love.event.quit()
    end
end

--[[
    LÖVE2D callback fired each time a mouse button is pressed; gives us the
    X and Y of the mouse, which we skip in this case.
]]
function love.mousepressed(_, _, button)
    love.mouse.buttonsPressed[button] = true
end

--[[
    Custom function to extend LÖVE's input handling; returns whether a given
    key was set to true in our input table this frame.
]]
function love.keyboard.wasPressed(key)
    return love.keyboard.keysPressed[key]
end

--[[
    Equivalent to our keyboard function from before, but for the mouse buttons.
]]
function love.mouse.wasPressed(button)
    return love.mouse.buttonsPressed[button]
end

function love.update(dt)
    -- scroll our background and ground, looping back to 0 after a certain amount
    if not PAUSED then
        backgroundScroll = (backgroundScroll + BACKGROUND_SCROLL_SPEED * dt) % BACKGROUND_LOOPING_POINT
        groundScroll = (groundScroll + GROUND_SCROLL_SPEED * dt) % VIRTUAL_WIDTH
    end

    if not PAUSED then
        Sounds['music']:play()
    else
        Sounds['music']:pause()
    end

    GStateMachine:update(dt)

    love.keyboard.keysPressed = {}
    love.mouse.buttonsPressed = {}
end

function love.draw()
    Push:start()

    love.graphics.draw(background, -backgroundScroll, 0)
    GStateMachine:render()
    love.graphics.draw(ground, -groundScroll, VIRTUAL_HEIGHT - 16)

    Push:finish()
end
