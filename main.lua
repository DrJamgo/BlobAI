if arg[#arg] == "-debug" then require("mobdebug").start() end

package.path = package.path .. ";" .. [[torch/pkg/?/init.lua]] .. ";" .. [[torch/extra/?/init.lua]] .. ";" .. [[torch/install/share/lua/5.1/?.lua]]
package.cpath = package.cpath .. ";" .. [[torch/install/lib/lua/5.1/?.so]]

require "blob"
require "stats"

require "nn"
require "profiler"

-- See https://github.com/soumith/cvpr2015/blob/master/Deep%20Learning%20with%20Torch.ipynb

net1 = nn.Sequential()
net1:add(nn.Linear(8, 6))
net1:add(nn.ReLU())
net1:add(nn.Linear(6, 4))
net1:add(nn.ReLU())

net2 = nn.Sequential()
net2:add(nn.Linear(4, 4))
net2:add(nn.ReLU())
net2:add(nn.Linear(4, 4))
net2:add(nn.ReLU())

function startProfile()
  calls, total, this = {}, {}, {}
  debug.sethook(function(event)
    local i = debug.getinfo(2, "Sln")
    if i.what ~= 'Lua' then return end
    local func = i.name or (i.source..':'..i.linedefined)
    if event == 'call' then
      this[func] = os.clock()
    else
      local time = os.clock() - this[func]
      total[func] = (total[func] or 0) + time
      calls[func] = (calls[func] or 0) + 1
    end
  end, "cr")
end

function endProfile()
  -- the code to debug ends here; reset the hook
  debug.sethook()
end

function printProfile()
  -- print the results
  for f,time in pairs(total) do
    print(("Function %s took %.3f seconds after %d calls"):format(f, time, calls[f]))
  end
end

function doNet(input)
  for j=1,16 do
    output = net1:forward(input)
  end
  output2 = net2:forward(output)
end

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
  for i=1,1 do
    start_time = love.timer.getTime()
    
    world.box2d_world:update(dt, 1, 1)
    
    for k,blob in pairs(world.blobs) do
      blob:update(dt)
      if blob.size < 2 then
        world.blobs[k] = nil
      end
      --doNet(torch.rand(8))
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
  
  love.graphics.setColor(0,1,0, 0.2)
  for k,food in pairs(world.food) do
    love.graphics.circle("fill", food.x, food.y, math.pow(food.food, 0.5))
  end
  
  for k,blob in pairs(world.blobs) do
    blob:draw()
  end
  
  --love.graphics.replaceTransform(love.math.newTransform(0,0,1))
    
  if options['s'] then stats:draw() end
end

function love.mousepressed(x, y, button, istouch)

end

function love.mousereleased(x, y, button, istouch)

end