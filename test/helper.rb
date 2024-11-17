%w[../xot ../rucy ../beeps ../rays ../reflex ../processing ../rubysketch .]
  .map  {|s| File.expand_path "../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'xot/test'
require 'rubysketch/all'
require 'reight/all'

require 'test/unit'

include Xot::Test


R8 = Reight
RS = RubySketch
