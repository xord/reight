require 'reight'
using Reight

def r8 = $r8

Reight::CONTEXT__.tap do |c|
  c.setup          {Reight::R8.new.setup}
  c.draw           {r8.draw}
  c.window_resized {r8.resized}
  c.key_pressed    {r8.key_pressed  key_code}
  c.key_released   {r8.key_released key_code}
end
