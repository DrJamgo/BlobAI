require "nn"
require "gnuplot"

-- n_obj x 5 
--   dx
--   dy
--   dist
--   food
--   self.size
local input = torch.load("cache/input"..tostring(1))

local nn_po_vec = nn:Sequential()
nn_po_vec:add(nn.Narrow(2, 1, 2))

local NUM_CENTERS = 6
local NUM_PROPERTIES = 2
local nn_po_class = nn:Sequential()
nn_po_class:add(nn.Narrow(2, 3, NUM_PROPERTIES))
local nn_euclidean = nn.Euclidean(NUM_PROPERTIES, NUM_CENTERS)
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

local net1 = nn.Sequential()
net1:add(nn_merge)
net1:add(nn_mult)
net1:add(nn.Linear(NUM_CENTERS, 8, false))
net1:add(nn.Tanh())
net1:add(nn.Linear(8, 3, false))
net1:add(nn.Tanh())
net1:add(nn.Linear(3, 1, false))
net1:add(nn.Tanh())
net1:add(nn.Sum(2))
--> 2
net1:add(nn.Padding(1,2,nil,0))

local pred = net1:forward(input)

return nil
