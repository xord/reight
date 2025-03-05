require 'reight/all'


begin
  w, c = Reight::WINDOW__, Reight::CONTEXT__

  reight_classes = %i[Sprite Sound]
  c.class.constants
    .reject {_1 =~ /__$/}
    .reject {reight_classes.include? _1}
    .each   {self.class.const_set _1, c.class.const_get(_1)}
  reight_classes
    .each {self.class.const_set _1, Reight.const_get(_1)}

  w.__send__ :begin_draw
  at_exit do
    w.__send__ :end_draw
    Processing::App.new {w.show}.start if c.hasUserBlocks__ && !$!
  end
end
