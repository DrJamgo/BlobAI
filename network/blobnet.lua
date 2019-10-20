require "nn"
require "torch"
-- See https://github.com/soumith/cvpr2015/blob/master/Deep%20Learning%20with%20Torch.ipynb

local nn_po_vec = nn:Sequential()
nn_po_vec:add(nn.Narrow(2, 1, 2))

local NUM_CENTERS = 6
local NUM_PROPERTIES = 2
local nn_po_class = nn:Sequential()
nn_po_class:add(nn.Narrow(2, 3, NUM_PROPERTIES))
local nn_euclidean = nn.WeightedEuclidean(NUM_PROPERTIES, NUM_CENTERS)
nn_po_class:add(nn_euclidean)
nn_po_class:add(nn.SoftMin(1))
--> n_obj x NUM_CENTERS

local nn_merge = nn.ConcatTable(1)
nn_merge:add(nn_po_vec)
nn_merge:add(nn_po_class)
--> n_obj x 2

local nn_mult = nn.MM(true, false)
local t1 = torch.Tensor({{0,1,1}})
local t2 = torch.Tensor({{-2,-2}})
local output = nn_mult:forward({t1,t2})
--> NUM_CENTERS x 2

local net = nn.Sequential()
net:add(nn_merge)
net:add(nn_mult)
net:add(nn.Linear(NUM_CENTERS, 8, false))
net:add(nn.Tanh())
net:add(nn.Linear(8, 5))
net:add(nn.Tanh())
net:add(nn.Linear(5, 1))
net:add(nn.Tanh())
net:add(nn.Transpose())
net:add(nn.Sum(2)) -- <- dummy to remove one dimension
--> 2
net:add(nn.Padding(1,2,nil,0))
--net1:replace(function(module) return nn.Profile(module, 100, "Player Network") end)

for i,module in ipairs(net:listModules()) do
   print(module)
end

return net