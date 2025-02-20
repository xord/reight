require 'json'
require 'rubysketch/all'


module Reight
  Processing.alias_snake_case_methods__ Processing
  Processing.alias_snake_case_methods__ RubySketch

  WINDOW__, CONTEXT__ = Processing.setup__ RubySketch

  refine Object do
    context = CONTEXT__
    (Processing.funcs__(context) - Processing.events__(context)).each do |func|
      define_method func do |*args, **kwargs, &block|
        context.__send__ func, *args, **kwargs, &block
      end
    end
  end
end# Reight


require 'reight/extension'
require 'reight/helpers'
require 'reight/history'
require 'reight/button'
require 'reight/text'
require 'reight/index'

require 'reight/reight'
require 'reight/context'
require 'reight/project'
require 'reight/chip'
require 'reight/map'
require 'reight/sound'
require 'reight/app'
require 'reight/app/navigator'
require 'reight/app/runner'
require 'reight/app/sprite'
require 'reight/app/map'
require 'reight/app/sound'
