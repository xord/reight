class History

  def initialize(undos = [], redos = [])
    super()
    @undos, @redos   = undos, redos
    @group, @enabled = nil, true
  end

  def push(*actions)
    return if actions.empty? || disabled?
    if @group
      @group.push(*actions)
    else
      @undos.push actions
      @redos.clear
      update
    end
  end

  def group(&block)
    @group = group = [] unless @group
    block.call
  ensure
    if group
      @group = nil
      push(*group)
    end
  end

  def undo(&block)
    actions = @undos.pop || return
    disable do
      actions.reverse.each {|action| block.call action}
    end
    @redos.push actions
    update
  end

  def redo(&block)
    actions = @redos.pop || return
    disable do
      actions.each {|action| block.call action}
    end
    @undos.push actions
    update
  end

  def enable(state = true)
    return if state == @enabled
    @enabled = state
    @enabled ? enabled : disabled
  end

  def disable(&block)
    old = enabled?
    enable false
    if block
      begin
        block.call
      ensure
        enable old
      end
    end
  end

  def canUndo?()
    !@undos.empty?
  end

  def canRedo?()
    !@redos.empty?
  end

  def updated(&block)
    @updated = block
  end

  def enabled?()
    @enabled
  end

  def disabled?()
    !enabled?
  end

  def enabled()
  end

  def disabled()
  end

  def to_h(&dumpObject)
    {
      version: 1,
      undos: self.class.dump(@undos, &dumpObject),
      redos: self.class.dump(@redos, &dumpObject)
    }
  end

  def self.load(hash, &restoreObject)
    undos = restore hash['undos'], &restoreObject
    redos = restore hash['redos'], &restoreObject
    self.new undos, redos
  end

  private

  def update()
    @updated.call if @updated
  end

  def self.dump(xdos, &dumpObject)
    xdos.map do |actions|
      actions.map do |action, *args|
        [action.to_s, *args.map {|obj| dumpObject.call(obj) || obj}]
      end
    end
  end

  def self.restore(xdos, &restoreObject)
    xdos.map do |actions|
      actions.map do |action, *args|
        [action.intern, *args.map {|obj| restoreObject.call(obj) || obj}]
      end
    end
  end

end# History
