

require 'core/diagram/code/stencil'
require 'core/system/load/load'
require 'core/schema/tools/print'

p = Dir['**/*.*'].find do |p|
  File.basename(p) == "schema.schema"
end    

RunStencilApp(p) # (SDs, Load('schema.schema'))
