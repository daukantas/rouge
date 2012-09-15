# encoding: utf-8
require 'spec_helper'
require 'rouge'

describe Rouge::Var do
  describe "the constructor" do
    it "creates an unbound var by default" do
      v = Rouge::Var.new(:boo)
      v.name.should eq :boo
      v.deref.should be_an_instance_of Rouge::Var::Unbound
    end

    it "creates a bound var if requested" do
      v = Rouge::Var.new(:huh, 99)
      v.name.should eq :huh
      v.deref.should eq 99
    end
  end

  describe "equality" do
    it "considers two vars equal if their names are equal" do
      Rouge::Var.new(:a).should == Rouge::Var.new(:a)
      Rouge::Var.new(:a).should_not == Rouge::Var.new(:b)
      Rouge::Var.new(:a).should == Rouge::Var.new(:a, :a)
      Rouge::Var.new(:a, :a).should == Rouge::Var.new(:a, :a)
      Rouge::Var.new(:a, :a).should == Rouge::Var.new(:a, :b)
      Rouge::Var.new(:b, :a).should_not == Rouge::Var.new(:a, :b)
      Rouge::Var.new(:b, :a).should_not == Rouge::Var.new(:a, :a)
    end
  end

  describe "the stack" do
    it "should override a var's root" do
      v = Rouge::Var.new(:hello, :frank)
      v.deref.should eq :frank

      Rouge::Var.push({:hello => :joe})
      v.deref.should eq :joe

      Rouge::Var.push({:hello => :mark})
      v.deref.should eq :mark

      Rouge::Var.pop
      v.deref.should eq :joe

      Rouge::Var.pop
      v.deref.should eq :frank
    end
  end
end

describe Rouge::Var::Unbound do
  describe "the constructor" do
    it "creates an unbound var's value" do
      v = Rouge::Var.new(:boo)
      ub = Rouge::Var::Unbound.new(v)
      ub.var.should be v
    end
  end
end

# vim: set sw=2 et cc=80:
