RENAMES = {reflex: 'reflexion'}

def sh(cmd)
  puts cmd
  system cmd
end

def setup_dependencies(build: true, only: nil)
  gemspec_path = `git ls-files`.lines(chomp: true).find {|l| l =~ /\.gemspec$/}
  return unless gemspec_path

  gemspec = File.read gemspec_path
  name    = File.basename gemspec_path, '.gemspec'

  exts = File.readlines('Rakefile')
    .map {|l| l[%r|^\s*require\W+(\w+)/extension\W+$|, 1]}
    .compact
    .reject {|ext| ext == name}
  exts = exts & [only].flatten.map(&:to_s) if only

  exts.each do |ext|
    gem   = RENAMES[ext.to_sym].then {|s| s || ext}
    ver   = gemspec[/add_runtime_dependency.*['"]#{gem}['"].*['"]\s*~>\s*([\d\.]+)\s*['"]/, 1]
    opts  = '-c advice.detachedHead=false --depth 1'
    clone = "git clone #{opts} https://github.com/xord/#{ext}.git ../#{ext}"

    # 'rake subtree:push' pushes all subrepos, so cloning by new tag
    # often fails before tagging each new tag
    sh %( #{clone} --branch v#{ver} || #{clone} )
    sh %( cd ../#{ext} && rake ext )
  end
end

def tag_versions()
  tags = `git tag`.lines chomp: true
  vers = `git log --oneline ./VERSION`
    .lines(chomp: true)
    .map {|line| line.split.first[/^\w+$/]}
    .map {|hash| [`git cat-file -p #{hash}:./VERSION 2>/dev/null`[/[\d\.]+/], hash]}
    .select {|ver, hash| ver && hash}
    .reverse
    .to_h

  changes = File.read('ChangeLog.md')
    .split(/^\s*##\s*\[\s*v([\d\.]+)\s*\].*$/)
    .slice(1..-1)
    .each_slice(2)
    .to_h
    .transform_values(&:strip!)

  vers.to_a.reverse.each do |ver, hash|
    tag = "v#{ver}"
    break if tags.include?(tag)
    sh %( git tag -a -m \"#{changes[ver]&.gsub '"', '\\"'}\" #{tag} #{hash} )
  end
end
