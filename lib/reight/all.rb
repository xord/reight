require 'json'
require 'rubysketch/all'


module Reight
  Processing.alias_snake_case_methods__ Processing
  Processing.alias_snake_case_methods__ RubySketch

  WINDOW__              = Processing.setup__ RubySketch::Window, RubySketch::Context
  $processing_context__ = WINDOW__.context

  refine Object do
    context = WINDOW__.context
    (Processing.funcs__(context) - Processing.events__(context)).each do |func|
      define_method func do |*args, **kwargs, &block|
        $processing_context__.__send__ func, *args, **kwargs, &block
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
require 'reight/sprite'
require 'reight/chip'
require 'reight/map'
require 'reight/sound'
require 'reight/app'
require 'reight/app/navigator'
require 'reight/app/runner'
require 'reight/app/chips'
require 'reight/app/sprite'
require 'reight/app/map'
require 'reight/app/sound'
