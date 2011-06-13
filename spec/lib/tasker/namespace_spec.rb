require 'spec_helper'

describe Tasker::Namespace do
  describe "a new namespace" do
    context "with only a name" do
      subject { Tasker::Namespace.new( "foo" ) }

      its( :tasks ) { should == [] }
    end

    context "with all parameters" do
      let( :namespace_name ) { "dummy_namespace" }
      let( :namespace_options ) { { :foo => :bar } }
      let( :namespace_block ) { Proc.new { } }
      subject { Tasker::Namespace.new( namespace_name, namespace_options, &namespace_block ) }

      its( :name ) { should == namespace_name }
      its( :options ) { should == namespace_options }
      its( :block ) { should == namespace_block }
    end
  end

end
