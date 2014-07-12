require 'lib.middleclass'

local media      = require 'media'
local Map        = require 'map'
local drawDebug   = false  -- draw bump's debug info, fps and memory
local instructions = [[
  bump.lua demo

    left,right: move
    up:     jump/fly
    return: reset map
    delete: run garbage collection
    tab:    toggle debug info (%s)
]]

local map

function love.load()
  media.load()
  map = Map:new(4000, 2000) -- width, height
end

-- Updating
function love.update(dt)
  media.cleanup()

  -- Note that we only update elements that are visible to the camera. This is optional
  -- replace the map:update(dt, map:getVisible()) with the following line to update everything
  -- map:update(dt)
  map:update(dt, map:getVisible())
end

-- Drawing
function love.draw()
  map:draw(drawDebug)

  love.graphics.setColor(255, 255, 255)

  local w,h = love.graphics.getDimensions()

  local msg = instructions:format(tostring(drawDebug))
  love.graphics.printf(msg, w - 200, 10, 200, 'left')

  if drawDebug then
    local statistics = ("fps: %d, mem: %dKB\n sfx: %d"):format(love.timer.getFPS(), collectgarbage("count"), media.countInstances())
    love.graphics.printf(statistics, w - 200, h - 40, 200, 'right')
  end
end

-- Non-player keypresses

function love.keypressed(k)
  if k=="escape" then love.event.quit() end
  if k=="tab"    then drawDebug = not drawDebug end
  if k=="delete" then
    collectgarbage("collect")
  end
  if k=="return" then
    map:reset()
  end
end
