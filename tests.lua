require "nn"
require "gnuplot"

local net1 = nn.Sequential()
net1:add(nn.Max(1))

local input = torch.Tensor({{9,2,3},{3,4,5},{6,7,8}})

print(input)
print(net1:forward(input))


return nil
