module Reight::Activatable

  def initialize(...)
    super
    @active, @activateds = false, []
  end

  def active=(active)
    active  = !!active
    return if active == @active
    @active = active
    activated!
  end

  def active? = @active

  def activated(&block)
    @activateds.push block if block
  end

  def activated!()
    @activateds.each {_1.call active}
  end

end# Activatable


module Reight::Hookable

  def hook(*names)
    names.each do |name|
      singleton_class.__send__ :define_method, name do |&block|
        @hookable_hooks ||= {}
        (@hookable_hooks[name] ||= []).push block
      end
      singleton_class.__send__ :define_method, "#{name}!" do |*args|
        @hookable_hooks&.[](name)&.each {|block| block.call(*args)}
      end
    end
  end

end# Hookable


module Reight::HasHelp

  def initialize(...)
    super
    set_help name: name
  end

  def name = @name || self.class.name

  def set_help(name: nil, left: nil, right: nil)
    @helps = {name: name, left: left, right: right}
  end

  def help()
    name   = @helps[:name]
    mouses = @helps
      .values_at(:left, :right)
      .zip([:L, :R])
      .map {|help, char| help ? "#{char}: #{help}" : nil}
      .compact
      .then {_1.empty? ? nil : _1.join('  ')}
    [name, mouses].compact.join '   '
  end

end# HasHelp
