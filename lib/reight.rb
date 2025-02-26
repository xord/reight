require 'reight/all'


begin
  w, c = Reight::WINDOW__, Reight::CONTEXT__

  excludes = %i[Sound Sprite]
  c.class.constants
    .reject {_1 =~ /__$/}
    .reject {excludes.include? _1}
    .each   {self.class.const_set _1, c.class.const_get(_1)}

  w.__send__ :begin_draw
  at_exit do
    w.__send__ :end_draw
    Processing::App.new {w.show}.start if c.hasUserBlocks__ && !$!
  end
end
