--[[
-- Map class
-- The map is in charge of creaating the scenario where the game is played - it spawns a bunch of rocks, walls, floors and guardians, and a player.
-- Map:reset() restarts the map. It can be done when the player dies, or manually.
-- Map:update() updates the visible entities on a given rectangle (by default, what's visible on the screen). See main.lua to see how to update
-- all entities instead.
--]]
local class       = require 'lib.middleclass'
local bump        = require 'lib.bump'
local bump_debug  = require 'lib.bump_debug'
local gamera      = require 'lib.gamera'
local cameraman   = require 'lib.cameraman'

local media       = require 'media'

local Player      = require 'entities.player'
local Block       = require 'entities.block'
local Guardian    = require 'entities.guardian'

local random = math.random

local updateRadius = 100 -- how "far away from the camera" things stop being updated

local sortByUpdateOrder = function(a,b)
  return a:getUpdateOrder() < b:getUpdateOrder()
end

local sortByZ = function(a,b)
  return a:getZ() < b:getZ()
end

local Map = class('Map')

function Map:initialize(width, height)
  self.width  = width
  self.height = height

  self:reset()
end

function Map:getVisible()
  local l,t,w,h = self.camera:getVisible()
  return l - updateRadius, t - updateRadius, w + updateRadius * 2, h + updateRadius * 2
end

function Map:reset()
  --local music = media.music
  --music:rewind()
  --music:play()

  local width, height = self.width, self.height
  self.world  = bump.newWorld()
  self.player = Player:new(self, self.world, 60, 60)

  -- camera
  local gamera_cam = gamera.new(0,0, width, height)
  self.camera      =  cameraman.new(gamera_cam, self.player)

  -- walls & ceiling
  Block:new(self.world,        0,         0, width,        32, true)
  Block:new(self.world,        0,        32,    32, height-64, true)
  Block:new(self.world, width-32,        32,    32, height-64, true)

  -- tiled floor
  local tilesOnFloor = 40
  for i=0,tilesOnFloor - 1 do
    Block:new(self.world, i*width/tilesOnFloor, height-32, width/tilesOnFloor, 32, true)
  end

  -- groups of blocks
  local l,t,w,h, area
  for i=1,60 do
    w = random(100, 400)
    h = random(100, 400)
    area = w * h
    l = random(100, width-w-200)
    t = random(100, height-h-100)


    for i=1, math.floor(area/7000) do
      Block:new( self.world,
                 random(l, l+w),
                 random(t, t+h),
                 random(32, 100),
                 random(32, 100),
                 random() > 0.75 )
    end
  end

  for i=1,10 do
    Guardian:new( self.world,
                  self.player,
                  self.camera,
                  random(100, width-200),
                  random(100, height-150) )
  end

end


function Map:update(dt, l,t,w,h)
  l,t,w,h = l or 0, t or 0, w or self.width, h or self.height
  local visibleEntities, len = self.world:queryRect(l,t,w,h)

  table.sort(visibleEntities, sortByUpdateOrder)

  local entity
  for i=1, len do
    entity = visibleEntities[i]
    if entity:isInWorld() then entity:update(dt) end
  end

  self.camera:update(dt)
end

function Map:draw(drawDebug)
  self.camera:draw(function(l,t,w,h)
    if drawDebug then
      bump_debug.draw(self.world, l,t,w,h)
    end

    local visibleEntities, len = self.world:queryRect(l,t,w,h)

    table.sort(visibleEntities, sortByZ)

    for i=1, len do
      visibleEntities[i]:draw(drawDebug)
    end
  end)
end


return Map
