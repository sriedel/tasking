require 'spec_helper'

describe Tasker::Namespace do
  describe "a new namespace" do
    let( :namespace_name ) { "dummy_namespace" }
    let( :namespace_options ) { { :foo => :bar } }
    let( :namespace_block ) { Proc.new { } }

    context "with only a name" do
      subject { Tasker::Namespace.new( namespace_name ) }

      its( :name ) { should == namespace_name }
      its( :options ) { should == {} }
      its( :block ) { should be_nil }
      its( :tasks ) { should == [] }
    end

    context "with all parameters" do
      subject { Tasker::Namespace.new( namespace_name, namespace_options, &namespace_block ) }

      its( :name ) { should == namespace_name }
      its( :options ) { should == namespace_options }
      its( :block ) { should == namespace_block }
      its( :tasks ) { should == [] }
    end
  end

end
