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
  
end

function Creature:draw()
  love.graphics.setColor(unpack(self.color or {1,1,1}))
  love.graphics.setLineWidth(0.1)
  love.graphics.circle("line", self.body:getX(), self.body:getY(), self.shape:getRadius())
end

function Creature:_move(dx, dy)
  
end

function Creature:_eat(target)
  
end

function Creature:_feed(target)
  
end

function Creature:_reproduce(target)
  
end