# encoding: utf-8
require 'piret/eval/context'
require 'piret/eval/builtins'

class Piret::Eval::Namespace
  @@namespaces = {}

  def initialize(name)
    @name = name
    @table = {}
    @refers = []
  end

  def refers(ns)
    @refers << ns if not @refers.include? ns
  end

  def [](key)
    if @table.include? key
      return @table[key]
    end

    @refers.each do |ns|
      begin
        return ns[key]
      rescue Piret::Eval::BindingNotFoundError
        # no-op
      end
    end

    raise Piret::Eval::BindingNotFoundError, key
  end

  def set_here(key, value)
    @table[key] = value
  end

  attr_reader :name
end

module Piret::Eval::Namespace::Vivifiers
  def self.piret
    ns = Piret::Eval::Namespace.new :piret
    Piret::Eval::Builtins.methods(false).each do |m|
      ns.set_here m, Piret::Builtin[Piret::Eval::Builtins.method(m)]
    end
    Piret::Eval::Builtins::SYMBOLS.each do |name, val|
      ns.set_here name, val
    end
    ns.refers Piret::Eval::Namespace[:ruby]
    ns
  end

  def self.ruby
    Piret::Eval::Namespace::Ruby.new
  end
end

class << Piret::Eval::Namespace
  def exists?(ns)
    Piret::Eval::Namespace.class_variable_get('@@namespaces').include? ns
  end

  def [](ns)
    r = Piret::Eval::Namespace.class_variable_get('@@namespaces')[ns]
    return r if r

    if not Piret::Eval::Namespace::Vivifiers.respond_to?(ns)
      Piret::Eval::Namespace.class_variable_get('@@namespaces')[ns] = new(ns)
    else
      Piret::Eval::Namespace.class_variable_get('@@namespaces')[ns] = \
          Piret::Eval::Namespace::Vivifiers.send(ns)
    end
  end
end

class Piret::Eval::Namespace::Ruby
  def [](name)
    Kernel.const_get name
  rescue NameError
    raise Piret::Eval::BindingNotFoundError
  end

  def set_here(name, value)
    Kernel.const_set name, value
  end

  def name
    :ruby
  end
end

# vim: set sw=2 et cc=80: