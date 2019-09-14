if arg[#arg] == "-debug" then require("mobdebug").start() end

package.path = package.path .. ";" .. [[torch/pkg/?/init.lua]] .. ";" .. [[torch/extra/?/init.lua]] .. ";" .. [[torch/install/share/lua/5.1/?.lua]]
package.cpath = package.cpath .. ";" .. [[torch/install/lib/lua/5.1/?.so]]

require "blob"
require "stats"

require "nn"


box2d_world = love.physics.newWorld(0, 0, true)

FOODSIZE = 5

world = {
  sizex=100,
  sizey=100,
  box2d_world=box2d_world
}

stats = Stats(world)

function love.load()

  world.food = {}
  
  for i=1,40 do
    world.food[i] = {
      x=love.math.random() * world.sizex,
      y=love.math.random() * world.sizey,
      food=FOODSIZE
    }
  end
  
  world.blobs = {}
  
  for i=1,10 do
    world.blobs[i] = Blob(world, love.math.random() * world.sizex, love.math.random() * world.sizey)
  end
  
  love.window.setMode( 800, 800)

end

local foodspawn = 0

function love.update(dt)
  
  local totaltime = 0
  for i=1,10 do
    start_time = love.timer.getTime()
    
    world.box2d_world:update(dt, 1, 1)
    
    for k,blob in pairs(world.blobs) do
      blob:update(dt)
      if blob.size < 2 then
        world.blobs[k] = nil
      end
    end
    
    foodspawn = foodspawn - dt
    if foodspawn < 0 then
      foodspawn = 1
      world.food[#world.food+1] = {
        x=love.math.random() * world.sizex,
        y=love.math.random() * world.sizey,
        food=FOODSIZE
      }
    end
    end_time = love.timer.getTime()

    stats.elapsed_time = end_time - start_time
    totaltime = totaltime + stats.elapsed_time
    stats:update()
    
    if totaltime > 1 / 60 then
      break
    end
    
  end
end

options = {}
function love.keypressed( key, scancode, isrepeat )
  if options[key] then
    options[key] = nil
  else
    options[key] = {}
  end
end

function love.draw()
  
  sx = (love.graphics.getWidth()) / (world.sizex + 20)
  transform = love.math.newTransform( 10 * sx, 10 * sx, 0, sx, sx)
  love.graphics.replaceTransform( transform )
  
  for k,blob in pairs(world.blobs) do
    blob:draw()
  end
  
  love.graphics.setColor(0,1,0)
  for k,food in pairs(world.food) do
    love.graphics.circle("fill", food.x, food.y, math.pow(food.food, 0.5))
  end
  
  --love.graphics.replaceTransform(love.math.newTransform(0,0,1))
    
  if options['s'] then stats:draw() end
end

function love.mousepressed(x, y, button, istouch)

end

function love.mousereleased(x, y, button, istouch)

end