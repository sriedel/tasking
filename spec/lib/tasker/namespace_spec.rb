require 'spec_helper'

describe Tasker::Namespace do
  describe "a new namespace" do
    let( :namespace_name ) { "dummy_namespace" }
    let( :namespace_options ) { { :foo => :bar } }

    context "with only a name" do
      subject { Tasker::Namespace.new( namespace_name ) }

      its( :name ) { should == namespace_name }
      its( :options ) { should == {} }
      its( :tasks ) { should == [] }
    end

    context "with all parameters" do
      subject { Tasker::Namespace.new( namespace_name, namespace_options ) }

      its( :name ) { should == namespace_name }
      its( :options ) { should == namespace_options }
      its( :tasks ) { should == [] }
    end
  end

end
