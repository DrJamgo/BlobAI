
-- adds torch modules to package.path variable

package.path = package.path
  .. ";" .. [[torch/pkg/?/init.lua]]
  .. ";" .. [[torch/extra/?/init.lua]]
  .. ";" .. [[torch/install/share/lua/5.1/?.lua]]
  
package.cpath = package.cpath
  .. ";" .. [[torch/install/lib/lua/5.1/?.so]]
