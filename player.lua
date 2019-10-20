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

local nn_perObject = nn:Sequential()
nn_perObject:add(nn.Narrow(2, 1, 4))
nn_perObject:add(nn.Linear(4, 16))
nn_perObject:add(nn.Tanh())
nn_perObject:add(nn.Linear(16, 16))
nn_perObject:add(nn.Tanh())
nn_perObject:add(nn.Max(1))

local nn_state = nn.Sequential()
nn_state:add(nn.Narrow(2, 5, 1))
nn_state:add(nn.Max(1))

local nn_merge = nn.Concat(1)
nn_merge:add(nn_perObject)
nn_merge:add(nn_state)

local net1 = nn.Sequential()
net1:add(nn_merge)
net1:add(nn.Linear(17, 9))
net1:add(nn.Tanh())
net1:add(nn.Linear(9, 4))
net1:add(nn.Tanh())
--net1:replace(function(module) return nn.Profile(module, 100, "Player Network") end)

for i,module in ipairs(net1:listModules()) do
   --print(module)
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

local criterion = nn.Criterion()
criterion.c = nn.MSECriterion()
function criterion:updateOutput(input, target)
  local input_copy = input:clone()
  --input_copy[1] = input[1] * target[1]
  --input_copy[2] = input[2] * target[2]
  self.output = self.c:updateOutput(input_copy, target)
  return self.output
end

function criterion:updateGradInput(input, target)
  local gradInput = self.c:updateGradInput(input, target)
  --gradInput[1] = gradInput[1] * target[1]
  --gradInput[2] = gradInput[2] * target[2]
  self.gradInput = gradInput
  return self.gradInput
end

function trainNet()
  local epoch
  local dataset = {}
  local file_index = 1
  while file_exists("cache/input"..tostring(file_index)) do
    local input = torch.load("cache/input"..tostring(file_index))
    local shallOutput = torch.load("cache/shallOutput"..tostring(file_index))
    
    -- normal copy
    dataset[#dataset+1] = {input, shallOutput}
  
    if false then
      local input_hflip = input:clone()
      local input_vflip = input:clone()
      local input_hvflip = input:clone()
      local shallOutput_hflip = shallOutput:clone()
      local shallOutput_vflip = shallOutput:clone()
      local shallOutput_hvflip = shallOutput:clone()
      for c=1,input:size(1) do
        input_hflip[c][1] = -input_hflip[c][1]
        input_vflip[c][2] = -input_vflip[c][2]
        input_hvflip[c][1] = -input_hvflip[c][1]
        input_hvflip[c][2] = -input_hvflip[c][2]
      end
      
      shallOutput_hflip[1] = -shallOutput_hflip[1]
      shallOutput_vflip[2] = -shallOutput_vflip[2]
      shallOutput_hvflip[1] = -shallOutput_hvflip[1]
      shallOutput_hvflip[2] = -shallOutput_hvflip[2]
      
      -- Add flipped variations of the dataset pair
      dataset[#dataset+1] = {input_hflip, shallOutput_hflip}
      dataset[#dataset+1] = {input_vflip, shallOutput_vflip}
      dataset[#dataset+1] = {input_hvflip, shallOutput_hvflip}
    end

    file_index = file_index + 1
  end
  
  --for k,v in pairs(dataset) do
    --local input = dataset[k][1]
    --local length = math.sqrt((input[1] * input[1]) + (input[2] * input[2]))
    --dataset[k][1][1] = input[1] / length
    --dataset[k][1][2] = input[2] / length
  --end
  
  if #dataset > 0 then
    function dataset:size() return #dataset end
    
    trainer = nn.StochasticGradient(net1, criterion)
    trainer.learningRate = 0.025
    trainer.learningRateDecay = 0.02
    trainer.maxIteration = 20
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
    input[i][4] = objects[i].food or -objects[i].hazzard
    input[i][5] = self.size
  end

  local netOutput = net1:forward(input)

  self.control = 'player'
  if options['x'] then
    self.control = 'script'
    output = Blob.process(self, dt, objects)
  end
  
  if love.mouse.isDown(1) then
    mouse_x = love.mouse.getX()
    mouse_y = love.mouse.getY()
    local x,y = self.world.transform:inverseTransformPoint(love.mouse.getX(), love.mouse.getY())
    self.target = {x=x,y=y}
  end
  
  if love.mouse.isDown(2) then
    output.eat = true
  end
  
  if self:reproduceReady() and love.mouse.isDown(3) then
    output.reproduce = true
  end
  
  if self.target then
    local dx = self.target.x - self.body:getX()
    local dy = self.target.y - self.body:getY()
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist > 1.0 then
      output.dx = dx / dist
      output.dy = dy / dist
    else
      self.target = nil
    end
  end
  
  if love.keyboard.isDown('a') then output.dx = -0.9 end
  if love.keyboard.isDown('d') then output.dx = 0.9 end
  if love.keyboard.isDown('s') then output.dy = 0.9 end
  if love.keyboard.isDown('w') then output.dy = -0.9 end
  if love.keyboard.isDown('u') then output.eat = true end
  if love.keyboard.isDown('q') then output.reproduce = true end
  
  local shallOutput = torch.Tensor(4)
  shallOutput[1] = output.dx or 0
  shallOutput[2] = output.dy or 0
  shallOutput[3] = (output.eat and 0.9) or -0.9
  shallOutput[4] = (output.reproduce and 0.9) or -0.9
  
  if options['n'] then
    self.control = 'network'
    output.dx = netOutput[1]
    output.dy = netOutput[2]
    output.eat = netOutput[3] > 0.0
    output.reproduce = netOutput[4] > 0.0
  end
  
  if options['m'] then
    local gradInput = net1:backward(input, netOutput)
    
    self.net = {
        input=input,
        gradInput=gradInput
    }
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
    local color = (options['n'] and {1,0,0}) or (options['x'] and {1,1,1}) or {0.5,1,0.5}
    love.graphics.setColor(unpack(color))
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
    love.graphics.setColor(1,1,1)
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