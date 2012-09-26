# encoding: utf-8

module Rouge::Builtins
  require 'rouge/resolve'

  SYMBOLS = {
    :nil => nil,
    :true => true,
    :false => false,
  }
end

class << Rouge::Builtins
  def let(context, bindings, *body)
    context = Rouge::Context.new context
    bindings.each_slice(2) do |k, v|
      if k.ns
        raise Rouge::Context::BadBindingError,
            "cannot LET qualified name"
      end
      context.set_here k.name, context.eval(v)
    end
    self.do(context, *body)
  end

  def context(context)
    context
  end

  def quote(context, form)
    form
  end

  def fn(context, argv, *body)
    context = Rouge::Context.new(context)

    if argv[-2] == Rouge::Symbol[:&]
      rest = argv[-1]
      argv = argv[0...-2]
    elsif argv[-4] == Rouge::Symbol[:&] and argv[-2] == Rouge::Symbol[:|]
      rest = argv[-3]
      argv = argv[0...-4] + argv[-2..-1]
    else
      rest = nil
    end

    if argv[-2] == Rouge::Symbol[:|]
      block = argv[-1]
      argv = argv[0...-2]
    else
      block = nil
    end

    # Set initial values in the context so names resolve.
    argv.each.with_index do |arg, i|
      context.set_here(arg.name, nil)
    end
    context.set_here(rest.name, nil) if rest
    context.set_here(block.name, nil) if block

    # Now we resolve everything in the body.
    body = body.map {|form| Rouge::Resolve.resolve(form)}

    lambda {|*args, &blockgiven|
      if !rest ? (args.length != argv.length) : (args.length < argv.length)
        begin
          raise ArgumentError,
              "wrong number of arguments (#{args.length} for #{argv.length})"
        rescue ArgumentError => e
          orig = e.backtrace.pop
          e.backtrace.unshift "(rouge):?:FN call"
          e.backtrace.unshift orig
          raise e
        end
      end

      argv.each.with_index do |arg, i|
        context.set_here(arg.name, args[i])
      end
      context.set_here(rest.name, Rouge::Cons[*args[argv.length..-1]]) if rest
      context.set_here(block.name, blockgiven) if block

      self.do(context, *body)
    }
  end

  def def(context, name, *form)
    if name.ns != nil
      raise ArgumentError, "cannot def qualified var"
    end

    case form.length
    when 0
      context.ns.intern name.name
    when 1
      context.ns.set_here name.name, context.eval(form[0])
    else
      raise ArgumentError, "def called with too many forms #{form.inspect}"
    end
  end

  def if(context, test, if_true, if_false=nil)
    # Note that we rely on Ruby's sense of truthiness. (only false and nil are
    # falsey)
    if context.eval(test)
      context.eval if_true
    else
      context.eval if_false
    end
  end

  def do(context, *forms)
    r = nil

    while forms.length > 0
      begin
        r = context.eval(forms.shift)
      rescue Rouge::Context::ChangeContextException => cce
        context = cce.context
      end
    end

    r
  end

  def ns(context, name, *args)
    ns = Rouge[name.name]
    ns.refer Rouge[:"rouge.builtin"]

    args.each do |arg|
      kind, *params = arg.to_a

      case kind
      when :use
        params.each do |use|
          ns.refer Rouge[use.name]
        end
      when :require
        params.each do |param|
          if param.is_a? Rouge::Symbol
            Kernel.require param.name.to_s
          elsif param.is_a? Array and
                param.length == 3 and
                param[0].is_a? Rouge::Symbol and
                param[1] == :as and 
                param[2].is_a? Rouge::Symbol
            unless Rouge::Namespace.exists? param[0].name
              context.readeval(File.read("#{param[0].name}.rg"))
            end
            Rouge::Namespace[param[2].name] = Rouge[param[0].name]
          end
        end
      else
        raise "TODO bad arg in ns: #{kind}"
      end
    end

    context = Rouge::Context.new ns
    raise Rouge::Context::ChangeContextException, context
  end

  def defmacro(context, name, *parts)
    if name.ns
      raise ArgumentError, "cannot defmacro fully qualified var"
    end

    if parts[0].is_a? Array
      args, *body = parts
      macro = Rouge::Macro[
        context.eval(Rouge::Cons[Rouge::Symbol[:fn], args, *body])]
    elsif parts.all? {|part| part.is_a? Rouge::Cons}
      arities = {}

      parts.each do |cons|
        args, *body = cons.to_a

        if !args.is_a? Array
          raise ArgumentError,
              "bad multi-form defmacro component #{args.inspect}"
        end

        if args.index(Rouge::Symbol[:|])
          arity = -1
        else
          arity = args.length
        end

        if arities[arity]
          raise ArgumentError, "seen same arity twice"
        end

        arities[arity] =
            context.eval(Rouge::Cons[Rouge::Symbol[:fn], args, *body])
      end

      macro = Rouge::Macro[
        lambda {|*args, &blockgiven|
          if arities[args.length]
            arities[args.length].call *args, &blockgiven
          elsif arities[-1]
            arities[-1].call *args, &blockgiven
          else
            raise ArgumentError, "no matching arity in macro"
          end
        }]
    else
      raise ArgumentError, "neither single-form defmacro nor multi-form"
    end

    context.ns.set_here name.name, macro
  end

  def apply(context, fun, *args)
    args =
        args[0..-2].map {|f| context.eval f} +
        context.eval(args[-1]).to_a
    # This is a terrible hack.
    context.eval(Rouge::Cons[
        fun,
        *args.map {|a| Rouge::Cons[Rouge::Symbol[:quote], a]}])
  end

  def var(context, symbol)
    context.locate symbol
  end

  def throw(context, throwable)
    exception = context.eval(throwable)
    begin
      raise exception
    rescue Exception => e
      # TODO
      #e.backtrace.unshift "(rouge):?:throw"
      raise e
    end
  end
  
  def try(context, *body)
    return unless body.length > 0

    form = body[-1]
    if form.is_a?(Rouge::Cons) and
       form[0].is_a? Rouge::Symbol and
       form[0].name == :finally
      finally = form[1..-1].freeze
      body.pop
    end

    catches = {}
    while body.length > 0
      form = body[-1]
      if !form.is_a?(Rouge::Cons) or
         !form[0].is_a? Rouge::Symbol or
         form[0].name != :catch
        break
      end

      body.pop
      catches[context.eval(form[1])] =
        {:bind => form[2],
         :body => form[3..-1].freeze}
    end

    r =
      begin
        self.do(context, *body)
      rescue Exception => e
        catches.each do |klass, caught|
          if klass === e
            subcontext = Rouge::Context.new context
            subcontext.set_here caught[:bind].name, e
            r = self.do(subcontext, *caught[:body])
            self.do(context, *finally) if finally
            return r
          end
        end
        self.do(context, *finally) if finally
        raise e
      end

    self.do(context, *finally) if finally
    r
  end

  def destructure(context, parameters, values, evalled=false, r={})
    # TODO: can probably move this elsewhere as a regular function.
    i = 0
    
    unless evalled
      if values[-2] == Rouge::Symbol[:|]
        block = context.eval(values[-1])
        block_supplied = true

        values = values[0...-2]
      end

      if values[-2] == Rouge::Symbol[:&]
        values =
            values[0...-2].map {|v| context.eval(v)} +
            context.eval(values[-1]).to_a
      else
        values =
            values.map {|v| context.eval(v)}
      end
    else
      values = values.dup
    end
    
    parameters = parameters.dup
    while parameters.length > 0
      p = parameters.shift

      if p == Rouge::Symbol[:&]
        r[parameters.shift] = values.freeze
        values = []
        next
      end

      if p == Rouge::Symbol[:|]
        if not block_supplied
          raise ArgumentError, "no block supplied"
        end

        r[parameters.shift] = block
        next
      end

      if values.length == 0
        raise ArgumentError, "fewer values than parameters"
      end

      if p.is_a? Array
        destructure(context, p, values.shift, true, r)
      else
        r[p] = values.shift
      end
    end

    if values.length > 0
      raise ArgumentError, "fewer parameters than values"
    end

    r
  end
end

# vim: set sw=2 et cc=80:
