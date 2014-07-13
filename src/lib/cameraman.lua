--[[
-- cameraman lib
-- * camera:shake() increases the intensity of the vibration
-- * camera:update(dt) decreases the intensity of the vibration slightly and moves the camera position near to the target
-- ]]

local cron = require 'lib.cron'

local maxShake                      = 5
local shakeIntensityDecreaseSpeed   = 4
local capturePositionFrequency      = 1/60
local capturePositionDuration       = 0.75 -- seconds
local averageSpeedExaggeration      = 10 -- 1        = no exaggeration

local maxDistanceToTarget = 150

local cameraman = {}

local CameraMan = {}
local CameraManMt = {__index = CameraMan}

function CameraMan:draw(drawDebug, f)
  self.camera:draw(function(l,t,w,h)

    f(l,t,w,h)

    if drawDebug then
      local target = self.target
      local cx, cy = target:getCenter()
      local vx, vy = self:getAverageTargetVelocity()

      love.graphics.setColor(0,255,255)
      love.graphics.circle('line', cx, cy, maxDistanceToTarget)
      love.graphics.circle('line', self.x, self.y, 20)


      love.graphics.rectangle('line', cx + vx - 10, cy + vy - 10, 20,20)
    end
  end)
end

function CameraMan:getVisible()
  return self.camera:getVisible()
end

function CameraMan:shake(intensity)
  intensity = intensity or 3
  self.shakeIntensity = math.min(maxShake, self.shakeIntensity + intensity)
end

function CameraMan:adjustToMaxDistanceToTarget()
  local target = self.target
  local cx, cy = target:getCenter()
  local dx, dy = self.x - cx, self.y - cy
  local d2     = dx*dx + dy*dy

  if d2 > maxDistanceToTarget * maxDistanceToTarget then
    local d = math.sqrt(d2)
    local ratio = maxDistanceToTarget / d
    self.x = cx + dx * ratio
    self.y = cy + dy * ratio
  end
end

function CameraMan:adjustToAverageTargetVelocity()
  local cx, cy = self.target:getCenter()
  local vx, vy = self:getAverageTargetVelocity()

  self.x = cx + vx
  self.y = cy + vy
end

function CameraMan:update(dt)

  self.timer:update(dt)

  self:adjustToAverageTargetVelocity()
  self:adjustToMaxDistanceToTarget()

  self.camera:setPosition(self.x, self.y)

  self.shakeIntensity = math.max(0 , self.shakeIntensity - shakeIntensityDecreaseSpeed * dt)

  if self.shakeIntensity > 0 then
    local x = self.x + (100 - 200*math.random(self.shakeIntensity)) * dt
    local y = self.y + (100 - 200*math.random(self.shakeIntensity)) * dt
    self.camera:setPosition(x,y)
  end
end

function CameraMan:pushTargetPosition()
  local target = self.target
  local cx,cy = target:getCenter()

  self.pastPositions[#self.pastPositions + 1] = {x=cx,y=cy}

  local maxPastPositions = capturePositionDuration / capturePositionFrequency

  if #self.pastPositions > maxPastPositions then
    table.remove(self.pastPositions, 1)
  end
end

function CameraMan:getAverageTargetVelocity()
  local pastPos = self.pastPositions
  local len = #pastPos
  if len < 2 then return 0,0 end

  local sumX, sumY = 0,0
  local pos
  local prev = pastPos[1]
  for i=2,len do
    pos = pastPos[i]
    sumX = sumX + (pos.x - prev.x)
    sumY = sumY + (pos.y - prev.y)
    prev = pos
  end

  local ratio = averageSpeedExaggeration / (len-1)

  return sumX * ratio, sumY * ratio
end

cameraman.new = function(camera, target)
  local x,y = target:getCenter()
  local self = setmetatable({
    camera          = camera,
    target          = target,
    shakeIntensity  = 0,
    x               = x,
    y               = y,
    pastPositions   = {{x=x,y=y}}
  }, CameraManMt)

  self.timer        = cron.every(capturePositionFrequency, CameraMan.pushTargetPosition, self)
  return self
end

return cameraman
