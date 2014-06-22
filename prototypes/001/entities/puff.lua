--[[
-- Puff Class
-- Represents a Puff of smoke, created either by explosions or by the Player's propulsion
-- Puffs don't interact with anything (they can be displaced by explosions)
-- They gradually change in shape & color until they disappear (lived & lifeTime are used for that)
-- Since puffs continuously change in size, we keep adding and removing them from the world (this is ok,
-- it's the same thing that bump does internally to move things around)
--]]

local class   = require 'lib.middleclass'
local util    = require 'util'
local Entity  = require 'entities.entity'

local Puff = class('Puff', Entity)

local defaultVx      = 0
local defaultVy      = -10
local defaultMinSize = 2
local defaultMaxSize = 10

function Puff:initialize(world, x, y, vx, vy, minSize, maxSize)
  vx, vy = vx or defaultVx, vy or defaultVy
  minSize = minSize or defaultMinSize
  maxSize = maxSize or defaultMaxSize

  local w,h = math.random(minSize, maxSize), math.random(minSize, maxSize)

  Entity.initialize(self, world, x-w/2, y-h/2, w, h)

  self.r, self.g, self.b = 255,255,100
  local duration = 0.1 + math.random()
  self.vx, self.vy = vx, vy
  self:tween(duration*0.5, self, {r=100,g=100,b=100}, 'outQuad')
  self:tween(duration*0.9, self, {w=50+w, h=50+h},   'outQuart')
  self:after(duration, Puff.destroy, self)
end

function Puff:update(dt)
  local cx, cy = self:getCenter()

  Entity.update(self, dt)

  if self:isAlive() then
    cx, cy = cx + self.vx * dt, cy + self.vy * dt
    self:move(cx - self.w / 2, cy - self.h / 2)
  end
end

function Puff:draw()
  util.drawFilledRectangle(self.l, self.t, self.w, self.h, self.r, self.g, self.b)
end

return Puff



