--[[
-- cameraman lib
-- * camera:shake() increases the intensity of the vibration
-- * camera:update(dt) decreases the intensity of the vibration slightly and moves the camera position near to the target
-- ]]

local maxShake = 5
local shakeIntensityDecreaseSpeed = 4

local maxDistance = 50

local cameraman = {}

local CameraMan = {}

function CameraMan:draw(f, drawDebug)
  self.camera:draw(function(l,t,w,h)
    if drawDebug then
    end
    f(l,t,w,h)
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

function CameraMan:update(dt)

  local target = self.target
  local tx, ty = target:getCenter()
  local vx, vy = target.vx, target.vy

  self:setPosition(tx, ty)

  self.shakeIntensity = math.max(0 , self.shakeIntensity - shakeIntensityDecreaseSpeed * dt)

  if self.shakeIntensity > 0 then
    local x,y = self.camera:getPosition()

    x = x + (100 - 200*math.random(self.shakeIntensity)) * dt
    y = y + (100 - 200*math.random(self.shakeIntensity)) * dt
    self:setPosition(x,y)
  end
end

cameraman.new = function(camera, target)
  return setmetatable({
    camera          = camera,
    target          = target,
    shakeIntensity  = 0
  },
  { __index = CameraMan }
  )
end

return cameraman
