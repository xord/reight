require 'reight'
using RubySketch

def r8 = $r8

setup         {Reight::R8.new.setup}
draw          {r8.draw}
windowResized {r8.resized}
keyPressed    {r8.keyPressed  keyCode}
keyReleased   {r8.keyReleased keyCode}
