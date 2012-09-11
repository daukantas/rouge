# encoding: utf-8
require 'piret/core'

module Piret::Eval
  require 'piret/context'
  require 'piret/namespace'

  class BindingNotFoundError < StandardError; end
  class ChangeContextException < Exception
    def initialize(context); @context = context; end
    attr_reader :context
  end
end

class << Piret::Eval
  def eval(context, *forms)
    return nil if forms.length.zero?

    while true
      form = forms.shift
      r =
        case form
        when Piret::Symbol
          eval_symbol context, form
        when Piret::Cons
          begin
            eval_cons context, form
          rescue Piret::Eval::ChangeContextException => cce
            context = cce.context
          end
        when Hash
          Hash[*
              form.map {|k,v| [eval(context, k), eval(context, v)]}.flatten(1)]
        when Array
          form.map {|f| eval context, f}
        else
          form
        end

      return r if forms.length.zero?
    end
  end

  private

  def eval_symbol(context, form)
    form = form.inner.to_s
    if form[0] == ?.
      form = form[1..-1]
      lambda {|receiver, *args, &block|
        receiver.send(form, *args, &block)
      }
    else
      will_new =
        if form[-1] == ?.
          form = form[0..-2]
          true
        end

      parts = form.split("/")

      if parts.length == 1
        sub = context
      elsif parts.length == 2
        sub = Piret::Namespace[parts.shift.intern]
      else
        raise "parts.length not in 1, 2" # TODO
      end

      lookups = parts[0].split(/(?<=.)\.(?=.)/)
      sub = sub[lookups.shift.intern]

      while lookups.length > 0
        sub = sub.const_get(lookups.shift.intern)
      end

      if will_new
        sub.method(:new)
      else
        sub
      end
    end
  end

  def eval_cons(context, form)
    fun = eval context, form[0]
    case fun
    when Piret::Builtin
      fun.inner.call context, *form.to_a[1..-1]
    when Piret::Macro
      eval context, fun.inner.call(*form.to_a[1..-1])
    else
      args = form.to_a[1..-1]

      if args.include? Piret::Symbol[:|]
        index = args.index Piret::Symbol[:|]
        if args.length == index + 2
          # Function.
          block = eval context, args[index + 1]
        else
          # Inline block.
          block = eval context,
              Piret::Cons[Piret::Symbol[:fn],
                          args[index + 1],
                          *args[index + 2..-1]]
        end
        args = args[0...index]
      else
        block = nil
      end

      args = args.map {|f| eval context, f}

      fun.call *args, &block
    end
  end
end

# vim: set sw=2 et cc=80:
