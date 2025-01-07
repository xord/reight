class Reight::History

  def initialize(undos = [], redos = [])
    super()
    @undos, @redos   = undos, redos
    @group, @enabled = nil, true
  end

  def append(*actions)
    return false if actions.empty? || disabled?
    if @group
      @group.push(*actions)
    else
      @undos.push actions
      @redos.clear
      update
    end
    true
  end

  def begin_grouping(&block)
    raise "Grouping cannot be nested" if @group
    @group = []
    block.call if block
  ensure
    end_grouping if block
  end

  alias group begin_grouping

  def end_grouping()
    raise "'begin_grouping' is missing" unless @group
    actions, @group = @group, nil
    append(*actions)
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

  def can_undo?()
    !@undos.empty?
  end

  def can_redo?()
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

  def to_h(&dump_object)
    {
      version: 1,
      undos: self.class.dump(@undos, &dump_object),
      redos: self.class.dump(@redos, &dump_object)
    }
  end

  def self.load(hash, &restore_object)
    undos = restore hash['undos'], &restore_object
    redos = restore hash['redos'], &restore_object
    self.new undos, redos
  end

  private

  def update()
    @updated.call if @updated
  end

  def self.dump(xdos, &dump_object)
    xdos.map do |actions|
      actions.map do |action, *args|
        [action.to_s, *args.map {|obj| dump_object.call(obj) || obj}]
      end
    end
  end

  def self.restore(xdos, &restore_object)
    xdos.map do |actions|
      actions.map do |action, *args|
        [action.intern, *args.map {|obj| restore_object.call(obj) || obj}]
      end
    end
  end

end# History
