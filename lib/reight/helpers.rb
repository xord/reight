module Activatable

  def initialize()
    super()
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


module Clickable

  def initialize()
    super()
    @clickeds = []
  end

  def clicked(&block)
    @clickeds.push block if block
  end

  def clicked!()
    @clickeds.each {_1.call self}
  end

end# Clickable
