--[[
-- Player Class
-- This entity collides "sliding" over walls and floors.
--
-- It also models flying (when at full health) and jumping (when not at full health).
--
-- Health continuously regenerates. The player can survive 1 hit from a grenade, but the second one needs to happen
-- at least 4 secons later. Otherwise they player will die.
--
-- The most interesting method is :update() - it's a high level description of how the player behaves
--
-- Players need to have a Map on their constructor because they will call map:reset() before dissapearing.
--
--]]
local class  = require 'lib.middleclass'
local util   = require 'util'
local media  = require 'media'

local Entity = require 'entities.entity'
local Debris = require 'entities.debris'
local Puff   = require 'entities.puff'

---
local Arm = class('Arm', Entity)
Arm.static.updateOrder = 2

local armFilter = function(other)
  local cname = other.class.name
  return cname == 'Guardian' or cname == 'Block'
end

function Arm:getZ()
  return self.z
end

function Arm:initialize(player, world, quad, z, offsetX)
  self.player   = player
  self.quad     = quad
  self.z        = z
  self.offsetX  = offsetX

  local _,_,w,h = quad:getViewport()
  Entity.initialize(self, world, player.l, player.t, w, h)
end

function Arm:update(dt)
  local pcx, pcy  = self.player:getCenter()
  local l,t       = pcx - self.w / 2, pcy - self.h / 2

  self:move(l,t)

  local offsetX = self.player.facing == 'right' and self.offsetX or -self.offsetX
  local future_l = l + offsetX
  local future_t = t

  local cols, len = self.world:check(self, future_l, future_t, armFilter)
  if len > 0 then
    l,t = cols[1]:getTouch()
    self:move(l,t)
  else
    self:move(future_l, future_t)
  end
end

function Arm:draw(drawDebug)
  local img = media.img.player
  love.graphics.setColor(255,255,255)
  if self.player.facing == 'right' then
    love.graphics.draw(img, self.quad, self.l, self.t)
  else
    love.graphics.draw(img, self.quad, self.l+self.w, self.t, 0, -1, 1)
  end

  if drawDebug then
    love.graphics.setColor(0,255,0)
    love.graphics.rectangle('line', self.l, self.t, self.w, self.h)
  end

end
---

local Player = class('Player', Entity)
Player.static.updateOrder = 1


local deadDuration  = 3   -- seconds until res-pawn
local runAccel      = 500 -- the player acceleration while going left/right
local brakeAccel    = 2000
local jumpVelocity  = 400 -- the initial upwards velocity when jumping
local beltWidth     = 2
local beltHeight    = 8
local extraWidth    = 30

local abs = math.abs

local playerFilter = function(other)
  local cname = other.class.name
  return cname == 'Guardian' or cname == 'Block'
end

function Player:initialize(map, world, x,y)
  local _,_,body_w, body_h = media.quad.player_body:getViewport()
  local _,_,_,      legs_h = media.quad.player_legs:getViewport()
  Entity.initialize(self, world, x, y, body_w + extraWidth, body_h + legs_h)
  self.health = 1
  self.deadCounter = 0
  self.map = map
  self.facing = "right"
  self.front_arm = Arm:new(self, world, media.quad.player_front_arm, 1.1, -(body_w/2 + 20))
  self.back_arm  = Arm:new(self, world, media.quad.player_back_arm,  0.9, body_w/2)
end

function Player:getZ()
  return 1
end

function Player:changeVelocityByKeys(dt)
  self.isJumpingOrFlying = false

  if self.isDead then return end

  local vx, vy = self.vx, self.vy

  if love.keyboard.isDown("left") then
    self.facing = "left"
    vx = vx - dt * (vx > 0 and brakeAccel or runAccel)
  elseif love.keyboard.isDown("right") then
    self.facing = "right"
    vx = vx + dt * (vx < 0 and brakeAccel or runAccel)
  else
    local brake = dt * (vx < 0 and brakeAccel or -brakeAccel)
    if math.abs(brake) > math.abs(vx) then
      vx = 0
    else
      vx = vx + brake
    end
  end

  if love.keyboard.isDown("up") and (self:canFly() or self.onGround) then -- jump/fly
    vy = -jumpVelocity
    self.isJumpingOrFlying = true
  end

  self.vx, self.vy = vx, vy
end

function Player:playEffects()
  if self.isJumpingOrFlying then
    if self.onGround then
      media.sfx.player_jump:play()
    else
      Puff:new(self.world,
               self.front_arm.l + self.front_arm.w / 2,
               self.front_arm.t + self.front_arm.h,
               20 * (1 - math.random()),
               50,
               2, 3)
      Puff:new(self.world,
               self.back_arm.l + self.back_arm.w / 2,
               self.back_arm.t + self.back_arm.h,
               20 * (1 - math.random()),
               50,
               2, 3)
      if media.sfx.player_propulsion:countPlayingInstances() == 0 then
        media.sfx.player_propulsion:play()
      end
    end
  else
    media.sfx.player_propulsion:stop()
  end

  if self.achievedFullHealth then
    media.sfx.player_full_health:play()
  end
end

function Player:changeVelocityByBeingOnGround()
  if self.onGround then
    self.vy = math.min(self.vy, 0)
  end
end

function Player:checkIfOnGround(ny)
  if ny < 0 then self.onGround = true end
end

function Player:moveColliding(dt)
  self.onGround = false
  local world = self.world

  local future_l = self.l + self.vx * dt
  local future_t = self.t + self.vy * dt

  local cols, len = world:check(self, future_l, future_t, playerFilter)
  if len == 0 then
    self:move(future_l, future_t)
  else
    local col, tl, tt, nx, ny, sl, st
    local visited = {}
    while len > 0 do
      col = cols[1]
      tl,tt,nx,ny,sl,st = col:getSlide()

      self:changeVelocityByCollisionNormal(nx, ny)
      self:checkIfOnGround(ny)

      self:move(tl,tt)

      if visited[col.other] then return end -- prevent infinite loops
      visited[col.other] = true

      cols, len = world:check(self, sl, st, playerFilter)
      if len == 0 then
        self:move(sl, st)
      end
    end
  end
end

function Player:updateHealth(dt)
  self.achievedFullHealth = false
  if self.isDead then
    self.deadCounter = self.deadCounter + dt
    if self.deadCounter >= deadDuration then
      self.map:reset()
    end
  elseif self.health < 1 then
    self.health = math.min(1, self.health + dt / 6)
    self.achievedFullHealth = self.health == 1
  end
end

function Player:update(dt)
  self:updateHealth(dt)
  self:changeVelocityByKeys(dt)
  self:changeVelocityByGravity(dt)
  self:playEffects()

  self:moveColliding(dt)
  self:changeVelocityByBeingOnGround(dt)
end

function Player:takeHit()
  if self.isDead then return end
  if self.health == 1 then
    for i=1,3 do
      Debris:new(self.world,
                 math.random(self.l, self.l + self.w),
                 self.t + self.h / 2,
                 255,255,255)

    end
  end
  self.health = self.health - 0.7
  if self.health <= 0 then
    self:die()
  end
end

function Player:die()
  media.music:stop()

  self.front_arm:destroy()
  self.back_arm:destroy()

  self.isDead = true
  self.health = 0
  for i=1,20 do
    Debris:new(self.world,
               math.random(self.l, self.l + self.w),
               math.random(self.t, self.t + self.h),
               255,0,0)
  end
  local cx,cy = self:getCenter()
  self.w = math.random(8, 10)
  self.h = math.random(8, 10)
  self.l = cx + self.w / 2
  self.t = cy + self.h / 2
  self.vx = math.random(-100, 100)
  self.vy = math.random(-100, 100)
  self.world:remove(self)
  self.world:add(self, self.l, self.t, self.w, self.h)
end

function Player:getColor()
  local g = math.floor(255 * self.health)
  local r = 255 - g
  local b = 0
  return r,g,b
end

function Player:canFly()
  return self.health == 1
end

function Player:draw(drawDebug)

  if not self.isDead then

    local img        = media.img.player
    local body       = media.quad.player_body
    local legs       = media.quad.player_legs

    local _,_,body_w,body_h = body:getViewport()
    local _,_,legs_w,legs_h = legs:getViewport()
    local extraWidth2 = extraWidth / 2

    love.graphics.setColor(255,255,255)

    if self.facing == 'right' then
      local legs_l, legs_t = self.l + body_w / 2 - legs_w / 2, self.t + body_w
      love.graphics.draw(img, legs, legs_l, legs_t)
      love.graphics.draw(img, body, self.l + extraWidth2, self.t)
    else
      love.graphics.draw(img, body, self.l - extraWidth2 + self.w, self.t, 0, -1, 1)
      local legs_l, legs_t = self.l + self.w + body_w/2 - legs_w, self.t + body_w
      love.graphics.draw(img, legs, legs_l, legs_t, 0, -1, 1)
    end
  end

  if drawDebug then
    if self.onGround then
      util.drawFilledRectangle(self.l, self.t + self.h - 4, self.w, 4, 255,255,255)
    end
    if self:canFly() then
      util.drawFilledRectangle(self.l - beltWidth, self.t + self.h/2 , self.w + 2 * beltWidth, beltHeight, 255,255,255)
    end
    love.graphics.setColor(0,255,0)
    love.graphics.rectangle('line', self.l, self.t, self.w, self.h)
  end
end

return Player
