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
  }
)

function Blob:_init(world, x, y, size, color)
  Creature:_init(self, world, x, y)
  self.size = size or 7
  self.splitsize = 10
  self.sense = 20
  self.speed = 5
  self.world = world
  self.color = color or {x / world.sizex, 0.5, y / world.sizey, 0.7}
  
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
    if closestDist < math.pow(self.size,0.5) + math.pow(closestFood.food, 0.5) then
      output.eat = true
    else
      output.dx = dx
      output.dy = dy
    end
  else
    -- do nothing, no food in sight
  end
  
  if self.size > 12 then
    output.reproduce = true
  end
  
  return output
end