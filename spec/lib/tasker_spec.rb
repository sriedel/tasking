require 'spec_helper'

describe Tasker do
  include Tasker

  describe "#task" do
  end

  describe '#namespace' do
    let( :namespace_name ) { "dummy_namespace" }
    let( :namespace_options ) { { :foo => :bar } }
    let( :namespace_block ) { Proc.new { } }

    before( :each ) do
      namespace( namespace_name, namespace_options, &namespace_block )
    end

    it "should add a namespace to Namespace.all" do
      expect { namespace( namespace_name, namespace_options, &namespace_block ) }.to change { Tasker::Namespace.all.size }.by(1)
    end

    context "the newly created namespace" do
      subject { Tasker::Namespace.all.last }

      its( :name ) { should == namespace_name }
      its( :options ) { should == namespace_options }
      its( :block ) { should == namespace_block }
    end
  end
end
