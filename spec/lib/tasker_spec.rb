require 'spec_helper'

describe Tasker do
  include Tasker

  before( :each ) do
    Tasker::Namespace.class_eval { @namespaces.clear if @namespaces }
  end

  describe "#task" do
    let( :task_name ) { "dummy_task" }
    let( :task_options ) { { :foo => :bar } }
    let( :task_block ) { Proc.new { } }

  end

  describe '#namespace' do
    let( :namespace_name ) { "dummy_namespace" }
    let( :namespace_options ) { { :foo => :bar } }
    let( :namespace_block ) { Proc.new { } }

    context "a top level namespace" do
      before( :each ) do
        namespace( namespace_name, namespace_options, &namespace_block )
      end

      it "should add the namespace to Namespace.all" do
        expect { namespace( namespace_name, namespace_options, &namespace_block ) }.to change { Tasker::Namespace.all.size }.by(1)
        Tasker::Namespace.all.last.name.should == namespace_name
      end
    end

    context "nested namespaces" do
      shared_examples_for( :a_nested_namespace ) do
        it "should have the outer namespace" do
          Tasker::Namespace.all.map(&:name).should include( "outer_namespace" )
        end
          
        it "should have the middle namespace" do
          Tasker::Namespace.all.map(&:name).should include( "outer_namespace::middle_namespace" )
        end
          
        it "should have the inner namespace" do
          Tasker::Namespace.all.map(&:name).should include( "outer_namespace::middle_namespace::inner_namespace" )
        end

        it "should have only the defined namespaces" do
          ( Tasker::Namespace.all.map(&:name) - [ "outer_namespace",
                                                  "outer_namespace::middle_namespace",
                                                  "outer_namespace::middle_namespace::inner_namespace" ] ).should == []
        end
      end

      context "explicitly nested" do
        before( :each ) do
          namespace( "outer_namespace" ) do
            namespace( "middle_namespace" ) { namespace "inner_namespace"  }
          end
        end

        it_should_behave_like( :a_nested_namespace )
      end

      context "namespaced namespaces" do
        before( :each ) do
          namespace "outer_namespace::middle_namespace::inner_namespace" 
        end
        
        it_should_behave_like( :a_nested_namespace )
      end

      context "nested and namespaced namespaces" do
        before( :each ) do
          namespace "outer_namespace" do
            namespace "middle_namespace::inner_namespace" 
          end
        end
        
        it_should_behave_like( :a_nested_namespace )
      end

      context "namespaced and nested namespaces" do
        before( :each ) do
          namespace "outer_namespace::middle_namespace" do
            namespace "inner_namespace"
          end
        end
        
        it_should_behave_like( :a_nested_namespace )
      end
    end
  end
end
