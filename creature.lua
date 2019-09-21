Creature = {}
Creature.__index = Creature
setmetatable(Creature, {
  __call = function (cls, ...)
    local self = setmetatable({}, cls)
    self:_init(...)
    return self
  end,
})

function Creature:_init(world, x, y)
  
end

function Creature:update(dt)
  -- 1 Find objects in sight
  local objects = self.world.food
  -- 2 call process function
  local output = self:process(dt, objects)
  -- 3 execute actions
  self:_move(output.dx or 0, output.dy or 0)
  
  if output.eat then 
    self:_eat(objects, dt)
  end
  self:_reproduce()
  
  self:_updateStatus(dt)
  self:_updatePhysics(dt)
end

function Creature:_move(dx,dy)
  self.body:setLinearVelocity(dx * self.speed, dy * self.speed)
  if dx or dy then
    self.dir = math.atan(dy, dx)
    self.dx = dx
    self.dy = dy
  end
end

function Creature:_eat(objects, dt)
  for k,food in pairs(objects) do
    dx = food.x - self.body:getX()
    dy = food.y - self.body:getY()
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist <= math.pow(self.size,0.5) then
      local eat_rate = 0.1 * self.size
      local eat = math.min(food.food, eat_rate * dt)
      self.size = self.size + eat
      food.food = food.food - eat
      break
    end
  end
end

function Creature:_reproduce()
  
end

function Creature:_updatePhysics(dt)
  self.body:getFixtures()[1]:destroy()
  self.shape:setRadius(math.pow(self.size,0.5))
  love.physics.newFixture( self.body, self.shape, 1)
  self.body:setMass(self.size)
  self.size = self.size - dt * math.pow(self.speed * self.size, 2) / 5000
end

function Creature:_updateStatus(dt)
  self.size = self.size - 0.1 * dt
end

function Creature:draw()
  love.graphics.setColor(unpack(self.color or {1,1,1}))
  love.graphics.setLineWidth(0.1)
  love.graphics.circle("fill", self.body:getX(), self.body:getY(), self.shape:getRadius())
end