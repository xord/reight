module Reight
  to_snake_case = -> names {
    names.map(&:to_s)
      .map {[_1, _1.gsub(/([a-z])([A-Z])/) {"#{$1}_#{$2.downcase}"}]}
  }

  # alias snake_case methods
  [Processing, RubySketch]
    .map {|mod| mod.constants.map {mod.const_get _1}}
    .flatten
    .select {_1.class == Module || _1.class == Class}
    .each do |klass|
      to_snake_case[klass.instance_methods false]
        .reject {|from, to| from =~ /__$/}
        .reject {|from, to| klass.method_defined? to}
        .each   {|from, to| klass.alias_method to, from}
    end

  w = (ENV['WIDTH']  || 500).to_i
  h = (ENV['HEIGHT'] || 500).to_i
  WINDOW__  = Processing::Window.new(w, h) {start}
  CONTEXT__ = RubySketch::Context.new WINDOW__

  excludes = to_snake_case[%i[
    setup draw
    keyPressed keyReleased keyTyped
    mousePressed mouseReleased mouseMoved mouseDragged
    mouseClicked doubleClicked mouseWheel
    touchStarted touchEnded touchMoved
    windowMoved windowResized motion
  ]].flatten.uniq
  refine Object do
    (CONTEXT__.methods - Object.instance_methods - excludes)
      .reject {_1 =~ /__$/} # methods for internal use
      .each do |method|
        define_method(method) do |*args, **kwargs, &block|
          CONTEXT__.__send__(method, *args, **kwargs, &block)
        end
      end
  end
end# Reight


require 'reight/helpers'
require 'reight/project'
require 'reight/history'
require 'reight/button'

require 'reight/reight'
require 'reight/chip'
require 'reight/map'
require 'reight/app'
require 'reight/app/navigator'
require 'reight/app/sprite'
require 'reight/app/map'
