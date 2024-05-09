--[[
    GD50
    Breakout Remake

    -- Powerup Class --

    Class author: Igor Bolshakov
    ibolsch+harvard@gmail.com

    Represents a powerup which will fall randomly out of bricks and can be caught with
    the player's paddle.
]]

Powerup = Class{}

function Powerup:init(x, y, isKey)
  -- simple positional and dimensional variables
  self.diameter = 16
  self.x = x
  self.y = y

  -- these variables are for keeping track of our velocity on both the
  -- X always equals to 0, since the powerup can move only downwards
  -- Speed is random in the range of 34 to 48
  self.dy = 33 + math.random(15)
  self.dx = 0

  self.isKey = isKey
end

--[[
    Expects an argument with a bounding box, be that a paddle or a brick,
    and returns true if the bounding boxes of this and the argument overlap.
]]
function Powerup:collides(target)
  -- first, check to see if the left edge of either is farther to the right
  -- than the right edge of the other
  if self.x > target.x + target.width or target.x > self.x + self.diameter then
    return false
  end

  -- then check to see if the bottom edge of either is higher than the top
  -- edge of the other
  if self.y > target.y + target.height or target.y > self.y + self.diameter then
    return false
  end

  -- if the above aren't true, they're overlapping
  return true
end

function Powerup:update(dt)
  self.y = self.y + self.dy * dt
end

function Powerup:render()
  -- GTexture is our global texture for all blocks
  -- GPowerupFrames is a table of quads mapping to each individual powerup skin in the texture
  if self.isKey then
    love.graphics.draw(GTextures['powerups'], GFrames['powerups'][10], self.x, self.y)
  else
    love.graphics.draw(GTextures['powerups'], GFrames['powerups'][math.random(1,9)], self.x, self.y)
  end
end
