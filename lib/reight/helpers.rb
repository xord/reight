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


module Reight::Clickable

  def initialize(...)
    super
    @clickeds = []
  end

  def clicked(&block)
    @clickeds.push block if block
  end

  def clicked!()
    @clickeds.each {_1.call self}
  end

end# Clickable


module Reight::HasHelp

  def initialize(...)
    super
    setHelp name: name
  end

  def name = @name || self.class.name

  def setHelp(name: nil, left: nil, right: nil)
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
