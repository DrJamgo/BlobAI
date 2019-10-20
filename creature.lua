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
  local objectsInSight = {}
  local objectsInRange = {}
  
  for k,object in pairs(self.world.objects) do
    dx = object.x - self.body:getX()
    dy = object.y - self.body:getY()
    local dist = math.max(math.abs(dx), math.abs(dy))
    if dist < self.sense then
      table.insert(objectsInSight, object)
    end
    dist = math.sqrt(dx*dx+dy*dy)
    if dist < math.pow(self.size,0.5) + math.pow(object.food or object.hazzard, 0.5) then
      table.insert(objectsInRange, object)
    end
  end
  
  -- 2 call process function
  local output
  if self.output and self.latch > 0 then
    output = self.output
    self.latch = self.latch - dt
  else
    output = self:process(dt, objectsInSight)
    self.output = output
    self.latch = 0.05 - dt
  end
  -- 3 execute actions
  
  if output.eat then
    self:_eat(objectsInRange, dt)
    self:_move(output.dx or 0 / 2,output.dy or 0 / 2)
  else
    self:_move(output.dx or 0, output.dy or 0)
  end
  if output.reproduce then 
    self:_reproduce()
  end
  
  self:_updateHazzard(dt, objectsInRange)
  self:_updateStatus(dt)
  self:_updatePhysics(dt)
end

function Creature:_move(dx,dy)
  local norm = math.max(0.1, math.sqrt(dx * dx + dy * dy))
  self.body:setLinearVelocity(dx * self.speed / norm, dy * self.speed / norm)
  if dx or dy then
    self.dir = math.atan(dy, dx)
  end
end

function Creature:_eat(objectsInRange, dt)
  for k,object in pairs(objectsInRange) do
    local eat_rate = 0.3 * self.size
    local eat
    if object.food then
      eat = math.min(object.food, eat_rate * dt)
      object.food = object.food - eat
    else
      eat = -eat_rate * 2 * dt
    end
    self.size = self.size + eat
  end
end

function Creature:reproduceReady()
  return not self.reproduce or self.reproduce <= 0
end

function Creature:_reproduce()
  if self:reproduceReady() then
    self.size = self.size / 2
    local new_blob = Player(self.world, self.body:getX() + 1, self.body:getY()+1, self.size, self.color)
    self.world.blobs[#self.world.blobs+1] = new_blob
    self.reproduce = 5
  end
end

function Creature:_updateHazzard(dt, objectsInRange)
  for k,object in pairs(objectsInRange) do
    if object.hazzard then
      self.size = self.size - object.hazzard * dt
    end
  end
end

function Creature:_updatePhysics(dt)
  self.body:getFixtures()[1]:destroy()
  self.shape:setRadius(math.pow(self.size,0.5))
  love.physics.newFixture( self.body, self.shape, 1)
  self.body:setMass(self.size)
  self.size = self.size - dt * math.pow(self.speed * self.size, 2) / 5000
end

function Creature:_updateStatus(dt)
  if self.reproduce and self.reproduce > 0 then self.reproduce = self.reproduce - dt end
  self.size = self.size - 0.05 * dt
  if self.size < 2 then
    self.deleteme = true
  end
end

function Creature:draw()
  love.graphics.setColor(unpack(self.color or {1,1,1}))
  love.graphics.setLineWidth(0.1)
  love.graphics.circle("fill", self.body:getX(), self.body:getY(), self.shape:getRadius())
  if options['v'] and options['g'] then
    love.graphics.rectangle("line", self.body:getX() - self.sense, self.body:getY() - self.sense, self.sense * 2, self.sense * 2)
  end
  
  
  --love.graphics.print(self.size, self.body:getX(), self.body:getY(), 0, 0.3)
end