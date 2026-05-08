ALL_REPO        = 'xord/all'
ALL_DIR         = '../all'
ALL_FETCH_DEPTH = 100

RENAMES = {reflex: 'reflexion'}

def sh(cmd)
  puts cmd
  system cmd
end

def setup_dependencies(only: nil)
  gemspec_path = `git ls-files`.lines(chomp: true).find {|l| l =~ /\.gemspec$/}
  return unless gemspec_path

  gemspec = File.read gemspec_path
  name    = File.basename gemspec_path, '.gemspec'

  exts = File.readlines('Rakefile')
    .map {|l| l[%r|^\s*require\W+([\w\-\_]+)/extension\W+$|, 1]}
    .compact
    .reject {|ext| ext == name}
  exts = exts & [only].flatten.map(&:to_s) if only
  return if exts.empty?

  unless setup_dependencies_via_monorepo(exts)
    setup_dependencies_via_each_repo_by_version(gemspec, exts)
  end

  exts.each {|ext| sh %( cd ../#{ext} && rake ext )}
end

def setup_dependencies_via_monorepo(exts)
  uuid = `git log -1 --format=%B`[/^\[\[([0-9a-fA-F-]+)\]\]$/, 1]
  return false unless uuid

  commit = setup_monorepo uuid
  return false unless commit

  Dir.chdir(ALL_DIR) {sh %( git checkout -q #{commit} )}

  exts.each {|ext| sh %( ln -snf all/#{ext} ../#{ext} )}
  true
end

def setup_monorepo(uuid)
  unless File.directory? ALL_DIR
    url = "https://github.com/#{ALL_REPO}.git"
    sh %( git clone --no-tags --depth #{ALL_FETCH_DEPTH} #{url} #{ALL_DIR} )
  end
  loop do
    commit = find_monorepo_commit uuid
    return commit if commit

    deepened = Dir.chdir ALL_DIR do
      before = `git rev-list --count HEAD`.to_i
      sh %( git fetch --deepen #{ALL_FETCH_DEPTH} )
      `git rev-list --count HEAD`.to_i > before
    end
    return nil unless deepened
  end
end

def find_monorepo_commit(uuid)
  Dir.chdir ALL_DIR do
    out = `git log origin/HEAD -F --grep="[[#{uuid}]]" --format=%H -1`.strip
    out.empty? ? nil : out
  end
end

def setup_dependencies_via_each_repo_by_version(gemspec, exts)
  exts.each do |ext|
    gem   = RENAMES[ext.to_sym].then {|s| s || ext}
    ver   = gemspec[/add_dependency.*['"]#{gem}['"].*['"]\s*~>\s*([\d\.]+)\s*['"]/, 1]
    opts  = '-c advice.detachedHead=false --depth 1'
    clone = "git clone #{opts} https://github.com/xord/#{ext}.git ../#{ext}"

    # 'rake subtree:push' pushes all subrepos, so cloning by new tag
    # often fails before tagging each new tag
    sh %( #{clone} --branch v#{ver} || #{clone} )
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
