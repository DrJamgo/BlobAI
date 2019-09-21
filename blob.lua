require "creature"

Blob = {}
Blob.__index =
setmetatable(Blob, {
  __index = Creature,
  __call = function (cls, ...)
    local self = setmetatable({}, cls)
    self:_init(...)
    return self
  end,
})

function Blob:_init(world, x,y,size)
  Creature:_init(self, world, x, y)
  self.size = size or 7
  self.splitsize = 10
  self.sense = 20
  self.speed = 5
  self.world = world
  self.color = {x / 100, y / 100, math.random(), 0.8}
  
  self.body = love.physics.newBody(world.box2d_world, x, y, "dynamic" )
  self.body:setFixedRotation(true)
  self.shape = love.physics.newCircleShape(math.pow(self.size,0.5))
  local fixture = love.physics.newFixture( self.body, self.shape, 1)
end

function Blob:_findClosestFood(objects)
  local closestFood = nil
  local closestDist = nil
  local closestDx = nil
  local closestDy = nil
  for k,food in pairs(objects) do
    if food.food and food.food > 0 then
      dx = food.x - self.body:getX()
      dy = food.y - self.body:getY()
      local dist = math.sqrt(dx * dx + dy * dy)
      if closestDist == nil or dist < closestDist then
        closestDist = dist
        closestFood = food
        closestDx = dx
        closestDy = dy
      end
    end
  end
  
  return closestFood, closestDist, closestDx, closestDy
end

function Blob:process(dt, objects)
  local output = {}
  local closestFood, closestDist, dx, dy = self:_findClosestFood(objects)
  
  if closestDist then
    if closestDist < math.pow(self.size - 1,0.5) then
      output.eat = true
    else
      output.dx = dx
      output.dy = dy
    end
  else
    -- do nothing, no food in sight
  end
  
  -- TODO: handle reproduction
  
  return output
end

function Blob:uupdate(dt)
  local dist = 1000
  local next_food
  local food_dir
  local dir
  for k,food in pairs(world.food) do
    dx = food.x - self.body:getX()
    dy = food.y - self.body:getY()
    this_dist = math.sqrt(dx * dx + dy * dy)
    if food.food > 0 and this_dist < dist and this_dist < self.sense then
      dist = this_dist
      next_food = food
      food_dir = math.atan2(dy,dx)
    end
  end
  
  if next_food then
    if dist < math.pow(self.size,0.5)  then
      local eat_rate = 0.1 * self.size
      local eat = math.min(next_food.food, eat_rate * dt)
      self.size = self.size + eat
      next_food.food = next_food.food - eat
    else
      dir = food_dir
    end
  else
    if self.delay and self.delay > 0 then
      
    else
      self.delay = 1
      self.dir = love.math.random() * math.pi * 2
    end
    dir = self.dir
  end
  
  self.size = self.size - 0.1 * dt
  
  if dir then
    self.body:setLinearVelocity(self.speed * math.cos(dir), self.speed * math.sin(dir))
    self.size = self.size - dt * math.pow(self.speed * self.size, 2) / 5000
  else
    self.body:setLinearVelocity(0,0)
  end
  
end