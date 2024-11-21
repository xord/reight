module Reight
  # alias snake_case methods
  [Processing, RubySketch]
    .map {|mod| mod.constants.map {mod.const_get _1}}
    .flatten
    .select {_1.class == Module || _1.class == Class}
    .each do |klass|
      klass.instance_methods(false)
        .map(&:to_s)
        .reject {_1 =~ /__$/}
        .map    {|from| [from, from.gsub(/([a-z])([A-Z])/) {"#{$1}_#{$2.downcase}"}]}
        .reject {|from, to| from == to}
        .reject {|from, to| klass.method_defined? to}
        .each   {|from, to| klass.alias_method to, from}
    end

  w = (ENV['WIDTH']  || 500).to_i
  h = (ENV['HEIGHT'] || 500).to_i
  WINDOW  = Processing::Window.new(w, h) {start}
  CONTEXT = RubySketch::Context.new WINDOW

  refine Object do
    (CONTEXT.methods - Object.instance_methods)
      .reject {_1 =~ /__$/} # method for internal use
      .each do |method|
        define_method(method) do |*args, **kwargs, &block|
          CONTEXT.__send__(method, *args, **kwargs, &block)
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
