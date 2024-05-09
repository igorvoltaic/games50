--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.ball = params.ball
    self.level = params.level

    self.recoverPoints = 5000

    self.paddleResizeScoreDelta = 0

    self.ball:send()
    self.balls = {self.ball}
    self.ballCount = 1

    self.powerup = nil
    self.powerupDropRate = 0.75
    self.keyPowerupActive = false
    self.keyPowerupCounter = 0.0
    self.keyPowerupDropRate = 0.8
end


function PlayState:update(dt)
    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            GSounds['pause']:play()
        elseif love.keyboard.wasPressed('escape') then
            love.event.quit()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        GSounds['pause']:play()
        return
    end

    -- update paddle position based on velocity
    self.paddle:update(dt)

    self.ballCount = #self.balls
    -- update balls positions based on velocity
    for _, ball in pairs(self.balls) do
        ball:update(dt)

        if ball:collides(self.paddle) then
            ball:bouncePaddle(self.paddle)
            GSounds['paddle-hit']:play()
        end
    end

    if self.powerup ~= nil then
        self.powerup:update(dt)

        if self.powerup:collides(self.paddle) then
          GSounds['recover']:play()
          if self.powerup.isKey then
                self.keyPowerupActive = true
                if #self.bricks > 1 then
                    self.keyPowerupCounter = 30.0
                else
                    self.keyPowerupCounter = 90.0
                end
          elseif self.ballCount < 3 then
              for _ = 1, 3 - self.ballCount do
                local b = Ball()
                b:placeOverPaddle(self.paddle)
                b:send()
                table.insert(self.balls, b)
              end
          end
          -- if caught dismiss powerup
          self.powerup = nil
        elseif self.powerup.y >= VIRTUAL_HEIGHT then
          -- if powerup goes below bounds dismiss it
          self.powerup = nil
        end
    end

    if self.keyPowerupCounter > 0 then
        self.keyPowerupCounter = self.keyPowerupCounter - 0.01
    else
        self.keyPowerupActive = false
        self.keyPowerupCounter = 0
    end


    for k, ball in pairs(self.balls) do
        -- detect collision across all bricks with the ball
        for j, brick in pairs(self.bricks) do

            if #self.bricks == 1 and brick.isKey then
                self.keyPowerupDropRate = 0.5
                self.powerupDropRate = 0.3
            end

            if not brick.inPlay then
                table.remove(self.bricks, j)
            end

            -- only check collision if we're in play
            if brick.inPlay and ball:collides(brick) then

                -- add to score and paddle resize delta
                local scoreToAdd = (brick.tier * 200 + brick.color * 25)
                if not brick.isKey then
                    self.score = self.score + scoreToAdd
                elseif brick.isKey and self.keyPowerupActive then
                    self.score = self.score + scoreToAdd
                end
                self.paddleResizeScoreDelta = self.paddleResizeScoreDelta + scoreToAdd

                -- trigger the brick's hit function, which removes it from play
                brick:hit(self.keyPowerupActive)

                -- do not drop powerups too often when there are more than one ball
                local canDropPowerup = math.random() > self.powerupDropRate
                if self.ballCount > 1 then
                   canDropPowerup = math.random() > self.powerupDropRate + 0.1 * (self.ballCount - 1)
                end

                if self.powerup == nil and canDropPowerup then
                    local isKey = math.random() > self.keyPowerupDropRate
                    self.powerup = Powerup(brick.x + 8, brick.y + 16 , isKey)
                end

                -- if we have enough points, recover a point of health
                if self.score > self.recoverPoints then
                    -- can't go above 3 health
                    self.health = math.min(3, self.health + 1)

                    -- multiply recover points by 2
                    self.recoverPoints = self.recoverPoints + math.min(100000, self.recoverPoints * 2)

                    -- play recover sound effect
                    GSounds['recover']:play()
                end

                -- if we have enoght points, resize a paddle
                if self.paddleResizeScoreDelta >= 500 * self.paddle.size then
                    -- play recover sound effect
                    if self.paddle.size < 4 then
                      GSounds['recover']:play()
                    end

                    -- resize paddle: change size to select correct sprite and change actual width 
                    self.paddle.size = math.min(4, self.paddle.size + 1)
                    self.paddle.width = 2 * 16 * self.paddle.size

                    -- reset resize counter
                    self.paddleResizeScoreDelta = 0
                end

                -- go to our victory screen if there are no more bricks left
                if self:checkVictory() then
                    GSounds['victory']:play()

                    GStateMachine:change('victory', {
                        level = self.level,
                        paddle = self.paddle,
                        health = self.health,
                        score = self.score,
                        highScores = self.highScores,
                        ball = ball,
                        recoverPoints = self.recoverPoints
                    })
                end

                ball:hits(brick)

                -- only allow colliding with one brick, for corners
                break
            end
        end

        if ball.y >= VIRTUAL_HEIGHT then
            table.remove(self.balls, k)
            self.ballCount = #self.balls
            if self.ballCount < 1 then
                -- if ball goes below bounds, revert to serve state and decrease health
                self.health = self.health - 1
                GSounds['hurt']:play()

                if self.health == 0 then
                    GStateMachine:change('game-over', {
                        score = self.score,
                        highScores = self.highScores
                    })
                else
                    GStateMachine:change('serve', {
                        paddle = self.paddle,
                        bricks = self.bricks,
                        health = self.health,
                        score = self.score,
                        highScores = self.highScores,
                        level = self.level,
                        recoverPoints = self.recoverPoints
                    })

                  -- resize paddle: change size to select correct sprite and change actual width 
                  self.paddle.size = math.max(1, self.paddle.size - 1)
                  self.paddle.width = 2 * 16 * self.paddle.size
                  -- reset resize counter
                  self.paddleResizeScoreDelta = 0
                end
            end
        end
    end

    -- for rendering particle systems
    for _, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function PlayState:render()
    -- render bricks
    for _, brick in pairs(self.bricks) do
        brick:render()
    end

    -- render all particle systems
    for _, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    self.paddle:render()

    for _, ball in pairs(self.balls) do
        ball:render()
    end
    if self.powerup ~= nil then
        self.powerup:render()
    end

    RenderScore(self.score)
    RenderHealth(self.health)
    if self.keyPowerupCounter > 10 then
        RenderKeyPowerup(self.keyPowerupActive)
    elseif math.fmod(math.floor(self.keyPowerupCounter * 10), 2) > 0 then
        RenderKeyPowerup(self.keyPowerupActive)
    end

    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(GFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for _, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end
    end

    return true
end
