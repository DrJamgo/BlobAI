require "blob"

Player = {}
Player.__index =
setmetatable(Player, {
  __index = Blob,
  __call = function (cls, ...)
    local self = setmetatable({}, cls)
    self:_init(...)
    return self
  end,
})

require "nn"
require "gnuplot"
-- See https://github.com/soumith/cvpr2015/blob/master/Deep%20Learning%20with%20Torch.ipynb

local own = nn.Module()
function own:updateGradInput(input, gradOutput)
  return gradOutput:clone()
end
function own:updateOutput(input)
  self.output = input:clone()
  return self.output
end

local net1 = nn.Sequential()
net1:add(nn.Linear(4, 6))
net1:add(nn.Tanh())
net1:add(own)
net1:add(nn.Linear(6, 4))
net1:add(nn.Tanh())

for i,module in ipairs(net1:listModules()) do
   print(module)
end

function file_exists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end

function trainNet()
  local epoch
  local criterion = nn.MSECriterion()

  local dataset = {}
  while file_exists("cache/input"..tostring(#dataset+1)) do
    local input = torch.load("cache/input"..tostring(#dataset+1))
    local shallOutput = torch.load("cache/shallOutput"..tostring(#dataset+1))
    dataset[#dataset+1] = {input, shallOutput}
  end
  
  function dataset:size() return #dataset end
  
  trainer = nn.StochasticGradient(net1, criterion)
  trainer.learningRate = 0.01
  trainer:train(dataset)

  torch.save("cache/net1", net1)
end

if file_exists("cache/net1") then
  net1 = torch.load("cache/net1")
else
  trainNet()
end

function Player:process(dt, objects)
  self.ticks = self.ticks or 1
  local output = {}
  
  local closestFood, closestDist, dx, dy = self:_findClosestFood(objects)
  local input = torch.Tensor(4)
  
  input[1] = dx or 0
  input[2] = dy or 0
  input[3] = (closestFood and 1) or 0
  input[4] = self.size
  
  local netOutput = net1:forward(input)

  self.control = 'player'
  if options['x'] then
    self.control = 'script'
    output = Blob.process(self, dt, objects)
  end
  if love.keyboard.isDown('a') then output.dx = -1 end
  if love.keyboard.isDown('d') then output.dx = 1 end
  if love.keyboard.isDown('s') then output.dy = 1 end
  if love.keyboard.isDown('w') then output.dy = -1 end
  if love.keyboard.isDown('u') then output.eat = true end
  if love.keyboard.isDown('q') then output.reproduce = true end
  
  local shallOutput = torch.Tensor(4)
  shallOutput[1] = output.dx or 0
  shallOutput[2] = output.dy or 0
  shallOutput[3] = (output.eat and 1) or 0
  shallOutput[4] = (output.reproduce and 1) or 0
  
  local gradOutput = - shallOutput + netOutput
  
  for i=1,gradOutput:size()[1] do
    if gradOutput[i] ~= gradOutput[i] then
      print("hell")
    end
  end
  
  if options['n'] then
    self.control = 'network'
    output.dx = netOutput[1]
    output.dy = netOutput[2]
    output.eat = netOutput[3] > 0.1
    output.reproduce = netOutput[4] > 0.5
  end
  
  torch.save("cache/input"..tostring(self.ticks), input)
  torch.save("cache/shallOutput"..tostring(self.ticks), shallOutput)
  
  self.shallOutput = shallOutput
  self.netOutput = netOutput
  self.input = input
  
  self.ticks = self.ticks + 1
  
  return output
end

function Player:drawNet()
  
  if self.ticks then
    
    love.graphics.print("ticks="..tostring(self.ticks).."   control="..self.control, 50, 10, 0, 1)
    
    love.graphics.print("input", 30, 40, 0, 1)
    for i=1,self.input:size()[1] do
      love.graphics.setColor(self.input[i],0,-self.input[i],1)
      love.graphics.circle("fill", 50, 50 + i*30, 10)
      love.graphics.setColor(1,1,1,1)
      love.graphics.circle("line", 50, 50 + i*30, 10)
    end
    
    love.graphics.print("script", 80, 40, 0, 1)
    for i=1,self.shallOutput:size()[1] do
      love.graphics.setColor(self.shallOutput[i],0,-self.shallOutput[i],1)
      love.graphics.circle("fill", 100, 50 + i*30, 10)
      love.graphics.setColor(1,1,1,1)
      love.graphics.circle("line", 100, 50 + i*30, 10)
    end
    love.graphics.print("net", 130, 40, 0, 1)
    for i=1,self.netOutput:size()[1] do
      love.graphics.setColor(self.netOutput[i],0,-self.netOutput[i],1)
      love.graphics.circle("fill", 150, 50 + i*30, 10)
      love.graphics.setColor(1,1,1,1)
      love.graphics.circle("line", 150, 50 + i*30, 10)
      love.graphics.print(tostring(self.netOutput[i]), 170, 50 + i*30)
    end
  end

end