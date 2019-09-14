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
  self.size = size or 7
  self.splitsize = 10
  self.sense = 20
  self.speed = 5
  self.world = world
  self.color = {x / 100, y / 100, math.random()}
  
  self.body = love.physics.newBody(world.box2d_world, x, y, "dynamic" )
  self.body:setFixedRotation(true)
  self.shape = love.physics.newCircleShape(math.pow(self.size,0.5))
  local fixture = love.physics.newFixture( self.body, self.shape, 1)
end

function Blob:update(dt)
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
      
      
      if self.size >= self.splitsize then
        
        new_splitsize = math.max(5,self.splitsize * math.sqrt(math.random() + 0.5))
        new_speed = self.speed * math.sqrt(math.random() + 0.5)
        
        new_blob = Blob(self.world, self.body:getX() + math.cos(food_dir) * self.size, self.body:getY() + math.sin(food_dir) * self.size, self.size / 2)
        
        self.size = self.size / 2
        new_blob.speed = new_speed
        for i=1,3 do
          new_blob.color[i] = math.max(0,math.min(1, self.color[i] + (math.random() - 0.5) * 0.2))
        end
        self.world.blobs[#self.world.blobs+1] = new_blob
      end
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
  self.body:getFixtureList()[1]:destroy()
  self.shape:setRadius(math.pow(self.size,0.5))
  love.physics.newFixture( self.body, self.shape, 1)
  self.body:setMass(self.size)
end