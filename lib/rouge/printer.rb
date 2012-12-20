# encoding: utf-8
require 'rouge/wrappers'

module Rouge::Printer
  class UnknownFormError < StandardError; end

  def self.print(form, out)
    case form
    when Integer
      out << form.to_s
    when Rational
      out << "#{form.numerator}/#{form.denominator}"
    when Rouge::Symbol
      if form.ns_s
        out << form.ns_s
        out << "/"
      end
      out << form.name_s
    when Symbol
      out << form.inspect
    when String
      out << form.inspect
    when Array
      out << "["
      form.each.with_index do |e, i|
        out << " " unless i.zero?
        print(e, out)
      end
      out << "]"
    when Rouge::Seq::Empty
      out << "()"
    when Rouge::Seq::Cons
      if form.length == 2 and form[0] == Rouge::Symbol[:quote]
        out << "'"
        print(form[1], out)
      elsif form.length == 2 and form[0] == Rouge::Symbol[:var]
        out << "#'"
        print(form[1], out)
      else
        out << "("
        form.each.with_index do |e, i|
          out << " " unless i.zero?
          print(e, out)
        end
        out << ")"
      end
    when Rouge::Var
      out << "#'#{form.ns}/#{form.name}"
    when Hash
      out << "{"
      form.each.with_index do |kv,i|
        out << ", " unless i.zero?
        print(kv[0], out)
        out << " "
        print(kv[1], out)
      end
      out << "}"
    when Set
      out << "\#{"
      form.each_with_index do |el, i|
        print el, out
        out << " " unless i == (form.size - 1)
      end
      out << "}"
    when NilClass
      out << "nil"
    when TrueClass
      out << "true"
    when FalseClass
      out << "false"
    when Class, Module
      if form.name
        out << "ruby/#{form.name.split('::').join('.')}"
      else
        out << form.inspect
      end
    when Rouge::Builtin
      out << "rouge.builtin/#{form.inner.name}"
    when Regexp
      out << "#\"#{form.source}\""
    else
      out << form.inspect
    end
  end
end

# vim: set sw=2 et cc=80:
