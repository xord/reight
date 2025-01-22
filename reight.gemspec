# -*- mode: ruby -*-


require_relative 'lib/reight/extension'


Gem::Specification.new do |s|
  glob = -> *patterns do
    patterns.map {|pat| Dir.glob(pat).to_a}.flatten
  end

  ext   = Reight::Extension
  name  = ext.name.downcase
  rdocs = glob.call *%w[README]

  s.name        = name
  s.version     = ext.version
  s.license     = 'MIT'
  s.summary     = 'A Retro Game Engine for Ruby.'
  s.description = 'A Retro Game Engine for Ruby.'
  s.authors     = %w[xordog]
  s.email       = 'xordog@gmail.com'
  s.homepage    = "https://github.com/xord/reight"

  s.platform              = Gem::Platform::RUBY
  s.required_ruby_version = '>= 3.0.0'

  s.add_dependency 'xot',        '~> 0.3.3', '>= 0.3.3'
  s.add_dependency 'rucy',       '~> 0.3.3', '>= 0.3.3'
  s.add_dependency 'beeps',      '~> 0.3.3', '>= 0.3.3'
  s.add_dependency 'rays',       '~> 0.3.3', '>= 0.3.3'
  s.add_dependency 'reflexion',  '~> 0.3.3', '>= 0.3.3'
  s.add_dependency 'processing', '~> 1.1',   '>= 1.1.3'
  s.add_dependency 'rubysketch', '~> 0.7.4', '>= 0.7.4'

  s.files            = `git ls-files`.split $/
  s.executables      = s.files.grep(%r{^bin/}) {|f| File.basename f}
  s.test_files       = s.files.grep %r{^(test|spec|features)/}
  s.extra_rdoc_files = rdocs.to_a
end
