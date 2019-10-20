require 'nn'
require 'gnuplot'

local criterion = nn.Criterion()
criterion.c = nn.MSECriterion()
function criterion:updateOutput(input, target)
  local input_copy = input:clone()
  local target_copy = target:clone()
  local diff = torch.Tensor(self.avg) - target
  self.weights = torch.abs(diff)
  self.weights[3] = self.weights[3] / 10000000
  self.weights[4] = self.weights[4] / 10000000
  local err = input_copy - target_copy
  err:cmul(self.weights)
  self.output = self.c:updateOutput(err, err:clone():fill(0))
  return self.output
end

function criterion:updateGradInput(input, target)
  local gradInput = self.c:updateGradInput(input, target:clone())
  self.gradInput = gradInput:clone():cmul(self.weights)
  return self.gradInput
end

local plot = {}
plot.buffer = {}
function plotResults(self, iteration, currentError)
  plot.buffer[iteration] = currentError
  
  if iteration % 5 == 1 or iteration == self.maxIteration then
    gnuplot.figure(3)
    gnuplot.plot({'Error', torch.Tensor(plot.buffer)})
  end
  if false then
    local err = {}
    local out = {{},{},{},{}}
    local shall = {{},{},{},{}}

    for i=1,#dataset do
      local pred = net1:forward(dataset[i][1])

      err[#err+1] = criterion:updateOutput(pred, dataset[i][2])
      for n=1,pred:size(1) do
        out[n][#out[n]+1] = pred[n]
        shall[n][#shall[n]+1] = dataset[i][2][n]
      end
    end
    
    gnuplot.figure(1)
    gnuplot.plot({
        {'dx', torch.Tensor(out[1]), '-'},
        {'dx(shall)', torch.Tensor(shall[1]), '-'}
      })
    
    gnuplot.figure(2)
    gnuplot.plot({
        {'dy', torch.Tensor(out[2]), '-'},
        {'dy(shall)', torch.Tensor(shall[2]), '-'}
      })
  
  end
end

function trainNet(net)
  local epoch
  dataset = {}
  local outputHist = {}
  local file_index = 1
  while file_exists("cache/input"..tostring(file_index)) do
    local input = torch.load("cache/input"..tostring(file_index))
    local shallOutput = torch.load("cache/shallOutput"..tostring(file_index))
    
    -- normal copy
    dataset[#dataset+1] = {input, shallOutput}
    for r=1,shallOutput:size(1) do
      if file_index == 1 then
        outputHist[r] = shallOutput[r]
      else
        outputHist[r] = outputHist[r] + (shallOutput[r] - outputHist[r]) / (file_index + 1)
      end
    end
  
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
  
  criterion.avg = outputHist
  
  --for k,v in pairs(dataset) do
    --local input = dataset[k][1]
    --local length = math.sqrt((input[1] * input[1]) + (input[2] * input[2]))
    --dataset[k][1][1] = input[1] / length
    --dataset[k][1][2] = input[2] / length
  --end
  
  if #dataset > 0 then
    function dataset:size() return #dataset end
    
    trainer = nn.StochasticGradient(net, criterion)
    trainer.learningRate = 0.01
    trainer.learningRateDecay = 0
    trainer.maxIteration = 25
    trainer.hookIteration = plotResults
    trainer:train(dataset)
    
    --print("Euclidean Weights (Classes): \n" .. tostring(nn_euclidean.weight))
    
  end
end