--[[
-- cameraman lib
-- * camera:shake() increases the intensity of the vibration
-- * camera:update(dt) decreases the intensity of the vibration slightly and moves the camera position near to the target
-- ]]

local maxShake = 5
local shakeIntensityDecreaseSpeed = 4

local maxDistance = 100

local cameraman = {}

local CameraMan = {}

function CameraMan:draw(drawDebug, f)
  self.camera:draw(function(l,t,w,h)

    f(l,t,w,h)

    if drawDebug then
      local target = self.target
      local cx, cy = target:getCenter()
      love.graphics.setColor(200,200,200)
      love.graphics.circle('line', cx, cy, maxDistance)

      love.graphics.circle('line', self.x, self.y, 20)
    end
  end)
end

function CameraMan:getVisible()
  return self.camera:getVisible()
end

function CameraMan:setPosition(x,y)
  self.camera:setPosition(x,y)
end

function CameraMan:shake(intensity)
  intensity = intensity or 3
  self.shakeIntensity = math.min(maxShake, self.shakeIntensity + intensity)
end

function CameraMan:adjustToMaxDistance()
  local target = self.target
  local cx, cy = target:getCenter()
  local dx, dy = self.x - cx, self.y - cy
  local d2     = dx*dx + dy*dy

  if d2 > maxDistance * maxDistance then
    local d = math.sqrt(d2)
    self.x = cx + dx * maxDistance / d
    self.y = cy + dy * maxDistance / d
  end
end

function CameraMan:update(dt)

  self:adjustToMaxDistance()

  self.camera:setPosition(self.x, self.y)

  self.shakeIntensity = math.max(0 , self.shakeIntensity - shakeIntensityDecreaseSpeed * dt)

  if self.shakeIntensity > 0 then
    local x,y = self.camera:getPosition()

    x = x + (100 - 200*math.random(self.shakeIntensity)) * dt
    y = y + (100 - 200*math.random(self.shakeIntensity)) * dt
    self:setPosition(x,y)
  end
end

cameraman.new = function(camera, target)
  local x,y = target:getCenter()
  return setmetatable({
    camera          = camera,
    target          = target,
    shakeIntensity  = 0,
    x               = x,
    y               = y
  },
  { __index = CameraMan }
  )
end

return cameraman
