# encoding: utf-8
require 'spec_helper'
require 'rouge'

describe Rouge::Context do
  before do
    @a = Rouge::Context.new nil
    @ab = Rouge::Context.new @a
    @abb = Rouge::Context.new @ab
    @ac = Rouge::Context.new @a
    @in_rl = Rouge::Context.new Rouge::Namespace[:"rouge.builtin"]
    @in_rl_nested = Rouge::Context.new @in_rl

    @a.set_here :root, 42
    @ab.set_here :root, 80
    @ac.set_here :non, 50
  end

  describe "the [] method" do
    it "should get the closest binding" do
      @a[:root].should eq 42
      @ab[:root].should eq 80
      @abb[:root].should eq 80
      @ac[:root].should eq 42
      # var, because it's from a namespace
      @in_rl[:let].root.should be_an_instance_of Rouge::Builtin
    end

    it "should raise an exception if a binding is not found" do
      lambda {
        @a[:non]
      }.should raise_exception(Rouge::Eval::BindingNotFoundError)
    end
  end

  describe "the ns method" do
    it "should get the namespace of a context that has one" do
      @in_rl.ns.should eq Rouge::Namespace[:"rouge.builtin"]
    end

    it "should get the namespace of a nested context that has one" do
      @in_rl_nested.ns.should eq Rouge::Namespace[:"rouge.builtin"]
    end

    it "should return nil if a context has none" do
      @a.ns.should eq nil
      @ab.ns.should eq nil
    end
  end

  describe "the set_here method" do
    it "should set in the given context, shadowing outer bindings" do
      @ac.set_here :root, 90
      @ac[:root].should eq 90
      @a[:root].should eq 42
    end
  end

  describe "the set_lexical method" do
    it "should set in the closest context" do
      @abb.set_lexical :root, 777
      @abb[:root].should eq 777
      @ab[:root].should eq 777
      @a[:root].should eq 42
    end

    it "should raise an exception if a closest binding is not found" do
      lambda {
        @abb.set_lexical :non, 10
      }.should raise_exception(Rouge::Eval::BindingNotFoundError)
    end
  end

  describe "the readeval method" do
    it "should read and eval a form in this context" do
      Rouge.should_receive(:read).with(:a).and_return(:b)
      Rouge.should_receive(:eval).with(@a, :b).and_return(:c)
      @a.readeval(:a).should eq :c
    end
  end
end

# vim: set sw=2 et cc=80:
