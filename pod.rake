# -*- mode: ruby -*-


github  = 'https://github.com/xord'
renames = {reflexion: 'reflex'}
regexp  = /add\w+dependency.*['"]([\w\-]+)['"].*['"]\s*~>\s*([\d\.]+)\s*['"]/
repos   = File.readlines('reight.gemspec', chomp: true)
  .map {|s| regexp.match(s)&.values_at 1, 2}
  .compact
  .to_h
  .transform_keys {|name| renames[name.to_sym].then {|s| s || name}}


task :clobber do
  sh %( rm -rf #{repos.keys.join ' '} )
end

task :setup

repos.each do |repo, ver|
  rakefile = "#{repo}/Rakefile"
  opts     = [
    '-c advice.detachedHead=false',
    '--no-single-branch',
    '--depth 1',
    "--branch #{ENV["#{repo.upcase}_BRANCH"] || ('v' + ver)}"
  ]

  task :setup => rakefile

  file rakefile do
    sh %( git clone #{opts.join ' '} #{github}/#{repo} )
    sh %( cd #{repo} && VENDOR_NOCOMPILE=1 rake vendor erb )
  end
end
