if arg[#arg] == "-debug" then require("mobdebug").start() end

require "find_torch"

require "tests"
require "blob"
require "player"
require "stats"

love.math.setRandomSeed(0)

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
  sizex=200,
  sizey=200,
  box2d_world=box2d_world
}

stats = Stats(world)

function love.load()

  love.graphics.setBackgroundColor( 0.5, 0.5, 0.5, 1 )
  world.food = {}
  
  for i=1,80 do
    world.food[i] = {
      x=love.math.random() * world.sizex,
      y=love.math.random() * world.sizey,
      food=FOODSIZE
    }
  end
  
  world.blobs = {}
  
  --for i=1,10 do
  --  world.blobs[i] = Blob(world, love.math.random() * world.sizex, love.math.random() * world.sizey)
  --end
  
  world.player = Player(world, 0.5 * world.sizex, 0.5 * world.sizey, nil, {1,1,1,0.7})
  table.insert(world.blobs, world.player)
  
  love.window.setMode( 800, 800)

end

local foodspawn = 0

function love.update(dt)
  if options['p'] then return end
  local dt = math.min(dt, 0.1)
  local totaltime = 0
  local steps = (options['y'] and 5) or 1
  for i=1,steps do
    start_time = love.timer.getTime()
    
    world.box2d_world:update(dt, 1, 1)
    
    for k,blob in pairs(world.blobs) do
      blob:update(dt)
      if blob.deleteme then
        world.blobs[k] = nil
      end
      
      if blob.body:getX() < 0 then blob.body:setX(0) end
      if blob.body:getY() < 0 then blob.body:setY(0) end
      if blob.body:getX() > world.sizex then blob.body:setX(world.sizex) end
      if blob.body:getY() > world.sizey then blob.body:setY(world.sizey) end
    end
    
    for k,food in pairs(world.food) do
      if food.food <= 0 then
        world.food[k] = nil
      end
      food.food = math.min(FOODSIZE, food.food + 0.1 * dt)
    end
    
    foodspawn = foodspawn - dt
    if foodspawn < 0 then
      foodspawn = 0.5
      world.food[#world.food+1] = {
        x=love.math.random() * world.sizex,
        y=love.math.random() * world.sizey,
        food=1
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

options = {
  x=true,  -- scipt animation
  p=true  -- pause
}

function love.keypressed( key, scancode, isrepeat )
  if options[key] then
    options[key] = nil
  else
    options[key] = true
  end
end

function love.draw()
  
  if options['p'] then
    love.graphics.print("pause [press P to unpause]", 50, 50)
  end
  
  if options['v'] then
    local sx = (love.graphics.getWidth()) / (world.sizex + 20)
    transform = love.math.newTransform( 10 * sx, 10 * sx, 0, sx, sx)
  elseif world.player then
    local s = world.player.sense
    transform = love.math.newTransform(world.player.sense * s,world.player.sense * s, 0, s, s, world.player.body:getX(), world.player.body:getY())
  end
  
  love.graphics.replaceTransform( transform )
  
  love.graphics.setColor(0,1,0, 0.2)
  love.graphics.rectangle("line",0,0,world.sizex,world.sizey)
  for k,food in pairs(world.food) do
    love.graphics.circle("fill", food.x, food.y, math.pow(food.food, 0.5))
  end
  
  for k,blob in pairs(world.blobs) do
    blob:draw()
  end
  
  love.graphics.replaceTransform(love.math.newTransform(0,0,0))
    
  if options['\t'] then stats:draw() end
  
  world.player:drawNet()
  
end

function love.mousepressed(x, y, button, istouch)

end

function love.mousereleased(x, y, button, istouch)

end