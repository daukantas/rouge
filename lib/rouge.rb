# encoding: utf-8

module Rouge; end

start = Time.now
metaclass = class << Rouge; self; end
metaclass.send(:define_method, :start) {start}

class << Rouge
  require 'rouge/wrappers'
  require 'rouge/symbol'
  require 'rouge/cons'
  require 'rouge/reader'
  require 'rouge/printer'
  require 'rouge/context'
  require 'rouge/repl'

  def print(form, out)
    Rouge::Printer.print form, out
  end

  def [](ns)
    Rouge::Namespace[ns]
  end

  def boot!
    return if @booted
    @booted = true

    core = Rouge[:"rouge.core"]
    core.refer Rouge[:"rouge.builtin"]

    user = Rouge[:user]
    user.refer Rouge[:"rouge.builtin"]
    user.refer Rouge[:"rouge.core"]
    user.refer Rouge[:ruby]

    Rouge::Context.new(user).readeval(
        File.read(Rouge.relative_to_lib('boot.rg')))
  end

  def repl(argv)
    boot!
    Rouge::REPL.repl(argv)
  end

  def relative_to_lib name
    File.join(File.dirname(File.expand_path(__FILE__)), name)
  end
end

# vim: set sw=2 et cc=80:
