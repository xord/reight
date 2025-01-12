
# Reight - A Retro Game Engine for Ruby

Reight is an open-source Ruby library inspired by the powerful [Processing](https://processing.org/) API, designed to make creative coding accessible and enjoyable for everyone. With support for both Mac and Windows, this library brings the joy of visual programming to Ruby developers.

## Features

- **Processing API Compatibility**: Leverage the well-known Processing API to create stunning visuals, animations, and interactive applications using Ruby.
- **Cross-Platform**: Works seamlessly on both macOS and Windows environments.
- **Ruby-Powered**: Enjoy the elegance and simplicity of Ruby while crafting creative projects.
- **Extensible and Open**: Modify and extend the library to fit your unique needs.

## Installation

Install the gem via RubyGems:

```bash
gem install reight
```

Or add it to your Gemfile:

```ruby
gem 'reight'
```

Then run:

```bash
bundle install
```

## Getting Started

Here’s a simple example to get you started:

```ruby
# Create a window and draw something
draw do
  background 0
	$sprites ||= project.maps.first.map(&:to_sprite)
	sprite $sprites
end
```

Run the script and watch your window come to life!

```
$ bundle exec r8 .
```

## Documentation

Comprehensive documentation and guides can be found [here](https://www.rubydoc.info/gems/reight/0.1/index).

## License

This project is licensed under the [MIT License](LICENSE).

---

Happy coding with Ruby and Processing!
