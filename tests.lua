require "nn"
require "gnuplot"

local input = torch.Tensor({{1,2,3},{3,4,5},{6,7,8},{9,10,11},{7,7,7}})
local t_hflip = torch.eye(5)

print(input)
print(t_hflip)

--local output = torch * t_hflip

--print(output)

--f = g +1 

return nil
