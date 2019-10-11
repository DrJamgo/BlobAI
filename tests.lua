require "nn"
require "gnuplot"

local input = torch.Tensor({{1,2,3},{3,4,5},{6,7,8},{9,10,11},{7,7,7}})
local t_hflip = torch.eye(5)


local criterion = nn.Criterion()
criterion.c = nn.MSECriterion(false)
function criterion:updateOutput(input, target)
  local input_copy = input:clone()
  input_copy[1] = input[1] * target[1]
  input_copy[2] = input[2] * target[2]
  self.output = self.c:updateOutput(input_copy, target)
  return self.output
end

function criterion:updateGradInput(input, target)
  local gradInput = self.c:updateGradInput(input, target)
  gradInput[1] = gradInput[1] * target[1]
  gradInput[2] = gradInput[2] * target[2]
  self.gradInput = gradInput
  return self.gradInput
end

local input = torch.Tensor({1,0})
local target = torch.Tensor({0.7,0.7})

local output = criterion:updateOutput(input, target)
local gradInput = criterion:updateGradInput(input, target)


local input = torch.Tensor({0,0})
local target = torch.Tensor({0.7,0.7})

local output = criterion:updateOutput(input, target)
local gradInput = criterion:updateGradInput(input, target)



return nil
