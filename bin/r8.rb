require 'reight'
using RubySketch

def r8 = $reight

setup         {Reight.new.setup}
draw          {r8.draw}
windowResized {r8.resized}
keyPressed    {r8.keyPressed keyCode}
