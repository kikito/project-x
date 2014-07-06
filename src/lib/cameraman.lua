--[[
-- cameraman lib
-- * camera:shake() increases the intensity of the vibration
-- * camera:update(dt) decreases the intensity of the vibration slightly and moves the camera position near to the target
-- ]]

local maxShake = 5
local shakeIntensityDecreaseSpeed = 4

local cameraman = {}

local CameraMan = {}

function CameraMan:draw(f)
  self.camera:draw(f)
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
  self.shakeIntensity = math.max(0 , self.shakeIntensity - shakeIntensityDecreaseSpeed * dt)

  if self.shakeIntensity > 0 then
    local x,y = self.camera:getPosition()

    x = x + (100 - 200*math.random(self.shakeIntensity)) * dt
    y = y + (100 - 200*math.random(self.shakeIntensity)) * dt
    self:setPosition(x,y)
  end
end

cameraman.new = function(camera)
  return setmetatable({camera = camera, shakeIntensity = 0}, {__index = CameraMan})
end

return cameraman
