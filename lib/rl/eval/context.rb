# encoding: utf-8

class RL::Eval::Context
  class BindingNotFoundError < StandardError; end

  def initialize(parent=nil)
    @parent = parent
    @table = {}
  end

  def [](key)
    if @table.include? key
      @table[key]
    elsif @parent
      @parent[key]
    else
      raise BindingNotFoundError, key
    end
  end

  def set_here(key, value)
    @table[key] = value
  end

  def set_lexical(key, value)
    if @table.include? key
      @table[key] = value
    elsif @parent
      @parent.set_lexical key, value
    else
      raise BindingNotFoundError, "setting #{key} to #{value.inspect}"
    end
  end
end

# vim: set sw=2 et cc=80:
