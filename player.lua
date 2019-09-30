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
require "torch"
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

local net2 = nn.Sequential()
net2:add(nn.Linear(5, 4))
net2:add(nn.Tanh())
net2:add(nn.Min(1))

local net3 = nn.Sequential()
net3:add(nn.Linear(5, 4))
net3:add(nn.Tanh())
net3:add(nn.Max(1))

local net4 = nn.Concat(1)
net4:add(net2)
net4:add(net3)

local net1 = nn.Sequential()
net1:add(net4)
net1:add(nn.Linear(8, 8))
net1:add(nn.Tanh())
net1:add(nn.Linear(8, 4))
net1:add(nn.Tanh())

for i,module in ipairs(net1:listModules()) do
   print(module)
end

function file_exists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end

local plot = {}
plot.buffer = {}
function plotResults(self, iteration, currentError)
  plot.buffer[iteration] = currentError
  gnuplot.plot({'Error', torch.Tensor(plot.buffer)})
end

function trainNet()
  local epoch
  local criterion = nn.MSECriterion()

  local dataset = {}
  while file_exists("cache/input"..tostring(#dataset+1)) do
    local input = torch.load("cache/input"..tostring(#dataset+1))
    local shallOutput = torch.load("cache/shallOutput"..tostring(#dataset+1))
    dataset[#dataset+1] = {input, shallOutput}
    
    local out = net1:forward(input)
  end
  
  if #dataset > 0 then
    function dataset:size() return #dataset end
    
    trainer = nn.StochasticGradient(net1, criterion)
    trainer.learningRate = 0.01
    trainer.learningRateDecay = 0.1
    trainer.maxIteration = 25
    trainer.hookIteration = plotResults
    trainer:train(dataset)

    torch.save("cache/net1", net1)
  end
end

if file_exists("cache/net1") then
  net1 = torch.load("cache/net1")
else
  trainNet()
end

function Player:process(dt, objects)
  self.ticks = self.ticks or 1
  local output = {}
  
  local input = torch.Tensor(math.max(#objects,1), 5)
  input[1]:fill(0)
  
  for i=1,#objects do
    input[i][1] = objects[i].x - self.body:getX()
    input[i][2] = objects[i].y - self.body:getY()
    input[i][3] = math.sqrt(math.pow(input[i][1], 2) + math.pow(input[i][2], 2))
    input[i][4] = objects[i].food or 0
    input[i][5] = self.size
  end

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
  
  if options['n'] then
    self.control = 'network'
    output.dx = netOutput[1]
    output.dy = netOutput[2]
    output.eat = netOutput[3] > 0.1
    output.reproduce = netOutput[4] > 0.5
    
    if options['m'] then
      local gradInput = net1:backward(input, netOutput)
      
      self.net = {
          input=input,
          gradInput=gradInput
      }
    end

  end
  
  torch.save("cache/input"..tostring(self.ticks), input)
  torch.save("cache/shallOutput"..tostring(self.ticks), shallOutput)
  
  self.shallOutput = shallOutput
  self.netOutput = netOutput
  self.input = input
  
  self.ticks = self.ticks + 1
  
  return output
end

function Player:draw()
  Blob.draw(self)
  
  if self.net and options['m'] then
    for c=1,self.net.input:size(1) do
      local input = self.net.input[c]
      local STEP_Y = 1.2
      local x = self.body:getX()+input[1]
      local y = self.body:getY()+input[2]
      for r=1,self.net.input:size(2) do
        local node = self.net.input[c][r]
        local value = node / 10
        local Y = y-(((self.net.input:size(2) / 2)-r+0.5)*STEP_Y)
        love.graphics.setColor(value,0,-value,1)
        love.graphics.circle("fill", x, Y, 0.5)
        love.graphics.setColor(1,1,1,1)
        love.graphics.circle("line", x, Y, 0.5)
        love.graphics.print(string.format("%.2f",tostring(node)), x + STEP_Y, Y,nil, 0.05)
        
        local grad = self.net.gradInput[c][r]
        value = grad * 10
        love.graphics.setColor(value,0,-value,math.abs(value))
        love.graphics.line(x,Y,self.body:getX(),self.body:getY())
      end
    end
  end
end

function Player:drawNet()
  
  if self.ticks then
    love.graphics.setColor(1,1,1)
    love.graphics.print("ticks="..tostring(self.ticks).."   control="..self.control, 50, 10, 0, 1)
    
    --[[
    love.graphics.print("input", 30, 40, 0, 1)
    for i=1,self.input:size()[1] do
      love.graphics.setColor(self.input[i],0,-self.input[i],1)
      love.graphics.circle("fill", 50, 50 + i*30, 10)
      love.graphics.setColor(1,1,1,1)
      love.graphics.circle("line", 50, 50 + i*30, 10)
    end
    ]]--
    
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