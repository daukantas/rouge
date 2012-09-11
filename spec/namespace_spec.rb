# encoding: utf-8
require 'spec_helper'
require 'rouge'

describe Rouge::Namespace do
  describe "the [] method" do
    it "should vivify non-extant namespaces" do
      Rouge::Namespace.exists?(:vivify_test).should eq false
      Rouge::Namespace[:vivify_test].should be_an_instance_of Rouge::Namespace
      Rouge::Namespace.exists?(:vivify_test).should eq true
    end
  end

  describe "the Rouge[] shortcut" do
    it "should directly call the [] method" do
      Rouge::Namespace.should_receive(:[]).with(:trazzle)
      Rouge[:trazzle]
    end
  end

  describe "the refer method" do
    it "should cause items in one namespace to be locatable from the other" do
      abc = Rouge::Namespace.new :abc
      xyz = Rouge::Namespace.new :xyz

      xyz.refer abc

      abc.set_here :hello, :wow
      xyz[:hello].should eq :wow
    end

    it "may not be used to refer namespaces to themselves" do
      lambda {
        Rouge[:user].refer Rouge[:user]
      }.should raise_exception(Rouge::Namespace::RecursiveNamespaceError)
    end
  end

  describe "the rouge.builtin namespace" do
    before do
      @ns = Rouge[:"rouge.builtin"]
    end

    it "should contain elements from Rouge::Builtins" do
      @ns[:let].should be_an_instance_of Rouge::Builtin
      @ns[:quote].should be_an_instance_of Rouge::Builtin
    end

    it "should contain fundamental objects" do
      @ns[:nil].should eq nil
      @ns[:true].should eq true
      @ns[:false].should eq false
    end

    it "should not find objects from ruby" do
      lambda {
        @ns[:Float]
      }.should raise_exception(Rouge::Eval::BindingNotFoundError)
      lambda {
        @ns[:String]
      }.should raise_exception(Rouge::Eval::BindingNotFoundError)
    end

    it "should have a name" do
      @ns.name.should eq :"rouge.builtin"
    end
  end

  describe "the ruby namespace" do
    before do
      @ns = Rouge::Namespace[:ruby]
    end

    it "should contain elements from Kernel" do
      @ns[:Hash].should eq Hash
      @ns[:Fixnum].should eq Fixnum
    end

    it "should have a name" do
      @ns.name.should eq :ruby
    end
  end
end

# vim: set sw=2 et cc=80: