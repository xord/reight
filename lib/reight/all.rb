require 'json'
require 'rubysketch/all'


module Reight
  Processing.alias_snake_case_methods__ Processing
  Processing.alias_snake_case_methods__ RubySketch

  WINDOW__, CONTEXT__, funcs, events = Processing.setup__ RubySketch

  refine Object do
    events = Processing.to_snake_case__(Processing::EVENT_NAMES__).flatten.uniq
    (funcs - events).each do |func|
      define_method func do |*args, **kwargs, &block|
        CONTEXT__.__send__ func, *args, **kwargs, &block
      end
    end
  end
end# Reight


require 'reight/extension'
require 'reight/helpers'
require 'reight/project'
require 'reight/history'
require 'reight/button'

require 'reight/reight'
require 'reight/chip'
require 'reight/map'
require 'reight/app'
require 'reight/app/navigator'
require 'reight/app/runner'
require 'reight/app/sprite'
require 'reight/app/map'
require 'reight/app/sound'
require 'reight/app/music'
