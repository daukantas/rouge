# encoding: utf-8
require 'spec_helper'
require 'rl'

describe RL::Eval::Namespace do
  describe "the refers method" do
    it "should cause items in one namespace to be locatable from the other" do
      abc = RL::Eval::Namespace.new :abc
      xyz = RL::Eval::Namespace.new :xyz

      xyz.refers abc

      abc.set_here :hello, :wow
      xyz[:hello].should eq :wow
    end
  end


  describe "the rl namespace" do
    before do
      @ns = RL::Eval::Namespace[:rl]
    end

    it "should contain elements from RL::Eval::Builtins" do
      @ns[:let].should be_an_instance_of RL::Builtin
      @ns[:quote].should be_an_instance_of RL::Builtin
    end

    it "should contain fundamental objects" do
      @ns[:nil].should eq nil
      @ns[:true].should eq true
      @ns[:false].should eq false
    end

    it "should find objects from R" do
      @ns[:Float].should eq Float
      @ns[:String].should eq String
    end

    it "should have a name" do
      @ns.name.should eq :rl
    end
  end

  describe "the r namespace" do
    before do
      @ns = RL::Eval::Namespace[:r]
    end

    it "should contain elements from Kernel" do
      @ns[:Hash].should eq Hash
      @ns[:Fixnum].should eq Fixnum
    end

    it "should have a name" do
      @ns.name.should eq :r
    end
  end
end

# vim: set sw=2 et cc=80:
