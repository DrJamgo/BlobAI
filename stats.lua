Stats = {}
Stats.__index = Stats
setmetatable(Stats, {
  __call = function (cls, ...)
    local self = setmetatable({}, cls)
    self:_init(...)
    return self
  end,
})

function Stats:_init(world)
  self.world = world
  self.stats = {}
end

function Stats:update(dt)
  local numblobs = 0
  local stats = {
    size=0,
    speed=0,
  }
  for k, blob in pairs(world.blobs) do
    numblobs = numblobs + 1
    for s, value in pairs(stats) do
      stats[s] = stats[s] - (stats[s] / (numblobs))  + blob[s] / (numblobs)
    end
  end
  
  stats.numblobs = numblobs
  
  self.stats[#self.stats+1] = stats
  if #self.stats > 4000 then
    table.remove(self.stats, 1)
  end
  
end

function Stats:draw()
  local x = 0
  local y = 100
  local step = 0.01
  
  for k,s in pairs({"speed", "size", "numblobs"}) do
    y = y - 10
    x = 0
    local val = 0
    for k,stats in pairs(self.stats) do
      x = x + step
      love.graphics.setColor(1,1,1)
      love.graphics.rectangle("fill",x,y,step,-stats[s])
      val = stats[s]
    end
    love.graphics.print(s .. "=" .. math.floor(val), x, y - val, 0, 0.2)
  end
  love.graphics.print(math.floor(self.elapsed_time * 1000 * 1000), 0, 0, 0, 0.3)
  
end