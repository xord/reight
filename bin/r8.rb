require 'reight'
using Reight

def r8 = $r8

Reight::CONTEXT__.tap do |c|
  c.setup          {Reight::R8.new.setup}
  c.draw           {r8.draw}
  c.key_pressed    {r8.key_pressed}
  c.key_released   {r8.key_released}
  c.key_typed      {r8.key_typed}
  c.mouse_pressed  {r8.mouse_pressed}
  c.mouse_released {r8.mouse_released}
  c.mouse_moved    {r8.mouse_moved}
  c.mouse_dragged  {r8.mouse_dragged}
  c.mouse_clicked  {r8.mouse_clicked}
  c.double_clicked {r8.double_clicked}
  c.mouse_wheel    {r8.mouse_wheel}
  c.touch_started  {r8.touch_started}
  c.touch_ended    {r8.touch_ended}
  c.touch_moved    {r8.touch_moved}
  c.window_moved   {r8.window_moved}
  c.window_resized {r8.window_resized}
end
