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
-- See https://github.com/soumith/cvpr2015/blob/master/Deep%20Learning%20with%20Torch.ipynb

local net1 = nn.Sequential()
net1:add(nn.Linear(4, 4))
net1:add(nn.Tanh())
net1:add(nn.Linear(4, 4))

function Player:process(dt, objects)
  local output = {}
  
  local closestFood, closestDist, dx, dy = self:_findClosestFood(objects)
  local input = torch.Tensor(4)
  
  input[1] = dx or 0
  input[2] = dy or 0
  input[3] = (closestFood and 1) or 0
  input[4] = self.size
  
  net1:zeroGradParameters()
  local netOutput = net1:forward(input)
  netOutput[3] = (netOutput[3] > 0.5) and 1 or 0 
  netOutput[4] = (netOutput[4] > 0.5) and 1 or 0
  
  if not options['x'] then
    output = Blob.process(self, dt, objects)
  end
  if love.keyboard.isDown('a') then output.dx = -1 end
  if love.keyboard.isDown('d') then output.dx = 1 end
  if love.keyboard.isDown('s') then output.dy = 1 end
  if love.keyboard.isDown('w') then output.dy = -1 end
  if love.keyboard.isDown('e') then output.eat = true end
  if love.keyboard.isDown('q') then output.reproduce = true end
  
  local shallOutput = torch.Tensor(4)
  shallOutput[1] = output.dx or 0
  shallOutput[2] = output.dy or 0
  shallOutput[3] = (output.eat and 1) or 0
  shallOutput[4] = (output.reproduce and 1) or 0
  
  local gradOutput = - shallOutput + netOutput
  gradOutput[4] = gradOutput[4] * 10
  
  for i=1,gradOutput:size()[1] do
    if gradOutput[i] ~= gradOutput[i] then
      print("hell")
    end
  end
  
  if options['n'] then
    output.dx = netOutput[1]
    output.dy = netOutput[2]
    output.eat = netOutput[3] > 0.5
    output.reproduce = netOutput[4] > 0.5
  else
    gradInput = net1:backward(input, gradOutput)
    net1:updateParameters(0.0001)
  end
  
  self.shallOutput = shallOutput
  self.netOutput = netOutput
  self.input = input
  
  return output
end

function Player:drawNet()
  for i=1,self.input:size()[1] do
    love.graphics.setColor(self.input[i],0,-self.input[i],1)
    love.graphics.circle("fill", 50, 10 + i*30, 10)
    love.graphics.setColor(1,1,1,1)
    love.graphics.circle("line", 50, 10 + i*30, 10)
  end
  for i=1,self.shallOutput:size()[1] do
    love.graphics.setColor(self.shallOutput[i],0,-self.shallOutput[i],1)
    love.graphics.circle("fill", 100, 10 + i*30, 10)
    love.graphics.setColor(1,1,1,1)
    love.graphics.circle("line", 100, 10 + i*30, 10)
  end
  for i=1,self.netOutput:size()[1] do
    love.graphics.setColor(self.netOutput[i],0,-self.netOutput[i],1)
    love.graphics.circle("fill", 140, 10 + i*30, 10)
    love.graphics.setColor(1,1,1,1)
    love.graphics.circle("line", 140, 10 + i*30, 10)
  end

end