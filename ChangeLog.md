# reight ChangeLog


## [v0.1.12] - 2025-05-22

- Add note_pressed, note_released, and control_change event handlers
- setTimeout() and setInterval() returns id without prefix


## [v0.1.11] - 2025-05-13

- Update dependencies


## [v0.1.10.1] - 2025-05-12

- Fix crash duaring launch


## [v0.1.10] - 2025-05-11

- Update dependencies


## [v0.1.9] - 2025-04-08

- Update README


## [v0.1.8] - 2025-03-24

- Add '--edit' command-line option to enable edit mode
- Add Text#editable?
- Add SpriteEditor::chips_index
- Add frame_changed and selection_changed to Sprite::Canvas
- Add Index control for maps
- Add PULL_REQUEST_TEMPLATE.md
- Add CONTRIBUTING.md
- Update layout
- Share the chips.rb
- Move chip_sizes above chips
- Refine visuals of button and index
- Index has min and max
- Text::initialize can take 'align:' keyword parameter
- The text input area will not be shaked if the value determined by the click is empty
- Fix the text value if not reverted on exiting edit mode with invalid value
- Delete App#name
- Simplify inspect() text
- Update readme: Add link to examples (by @kaibadash)

- Fix some crashes


## [v0.1.7] - 2025-03-07

- Add Reight::Context
- Add docs for Reight::Context
- Add Reight::Sprite class
- Add sound editor
- Add size() and createCanvas()
- Add App#active?
- Project: Add clear_all_sprites()
- Map: Add to_sprites(), sprites(), sprites_at(), clear_sprites()
- Map::Chunk: Add sprites(), clear_sprites(), and each()
- Chip: Add sprite(), clear_sprites(), and each()
- Add Map::SpriteArray class
- Add SpriteWorld#offset and SpriteWorld#zoom

- Define Sprite and Sound classes in the main context
- Change pixelsPerMeter from 100 to 8
- createSprite() creates a new Reight::Sprite instance
- Map: delete/delete_chip -> Map#remove/remove_chip
- Map::Chunk: Caches drawing contents
- Disable the '<=>' operators for Map, Map::Chunk, Chip, ChipList
- Sound: play() accepts a block parameter that is called when playback ends
- Sound: play() can take gain parameter
- Sound: Default gain: 0.1 -> 0.2
- Sound: apply envelope and gain
- Offset the button text while it is pressed

- Runner: During game execution, the Run button re-runs the game
- Runner: Delete F10 to restart
- Runner: Delete restart button
- Runner: Rescue exceptions raised by user script
- Runner: Stop all timers on stop running user script
- Runner: runner.rb does not use 'using Reight', so define funcs in runner context
- Runner: User script paths are relative to project directory

- SpriteEditor: Black is treated as a transparent color
- SpriteEditor: Update color palette to 32 colors
- SpriteEditor: Show color code

- SoundEditor: Cancel attack and release on successive notes to avoid click noise
- SoundEditor: Display tone colors on each tone button
- SoundEditor: Canvas is scrollable

- Fix pick_color fails to get pixel color
- Fix crash on moving window
- Fix crash on switching from editer to another editor
- Fix yard crash caused by pattern matching rightward assginment
- Fix misaligned mouse position on sound editor canvas
- Fix error on drawing line tool at map editor
- Fix the angle mode of Reight::Context does not sync with root context


## [v0.1.6] - 2025-01-30

- Update dependencies: processing, rubysketch


## [v0.1.5] - 2025-01-27

- Update dependencies


## [v0.1.4] - 2025-01-23

- On Windows, the 'path' environment variable is confused with 'PATH', so change it


## [v0.1.3] - 2025-01-15

- Refactoring: create_world() -> SpriteWorld.new()


## [v0.1.2] - 2025-01-14

- User can change the file name of user scripts
- Rename from 'bin/r8.rb' to 'bin/r8'
- Change the file/directory structure of the source code
- Update icon images
- Update workflow files
- Set minumum version for runtime dependency

- Fix an error on first launch


## [v0.1.1] - 2025-01-13

- Update README.md


## [v0.1] - 2025-01-13

- Alpha version
