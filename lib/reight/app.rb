using RubySketch


class App

  def sprites()
    []
  end

  def activate()
    sprites.each {|sp| addSprite sp}
  end

  def deactivate()
    sprites.each {|sp| removeSprite sp}
  end

end# App
