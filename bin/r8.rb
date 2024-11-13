require 'reight'
using Reight

def r8 = $r8

setup          {Reight::R8.new.setup}
draw           {r8.draw}
window_resized {r8.resized}
key_pressed    {r8.key_pressed  key_code}
key_released   {r8.key_released key_code}
