require "nn"
require "gnuplot"

local net1 = nn.Sequential()
net1:add(nn.Euclidean(3,3))

net1:zeroGradParameters()
local input1 = torch.Tensor({1,2,3})
local output1 = net1:forward(input1)

--gnuplot.plot({'I',input1,'|',},{'O', output1, 'x'})

return nil
