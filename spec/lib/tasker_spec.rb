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

    context "outside a namespace" do
      it "should raise an exception" do
        lambda { task( task_name ) }.should raise_error
      end
    end

    context "within a namespace" do
      before( :each ) do
        namespace( "outer_namespace" ) { task task_name }
      end

      it "should add the task to the namespaces task list" do
        registered_tasks = Tasker::Namespace.all.detect { |ns| ns.name == "outer_namespace" }.tasks
        registered_tasks.size.should == 1
        registered_tasks.first.name.should == task_name
      end
    end

    shared_examples_for( :a_task_in_a_nested_namespace ) do
      it "should add the task to the inner namespaces task list" do
        registered_tasks = Tasker::Namespace.all.detect { |ns| ns.name == "outer_namespace::inner_namespace" }.tasks
        registered_tasks.size.should == 1
        registered_tasks.first.name.should == task_name
      end

      it "should not add the task to the outer namespace task list" do
        registered_tasks = Tasker::Namespace.all.detect { |ns| ns.name == "outer_namespace" }.tasks
        registered_tasks.should == []
      end
    end

    context "within a nested namespace" do
      before( :each ) do
        namespace "outer_namespace" do
          namespace( "inner_namespace" ) { task task_name }
        end
      end

      it_should_behave_like( :a_task_in_a_nested_namespace )
    end

    context "within a namespaced namespace" do
      before( :each ) do
        namespace "outer_namespace::inner_namespace" do
          task task_name 
        end
      end
      it_should_behave_like( :a_task_in_a_nested_namespace )
    end

    context "with a namespaced name" do
      before( :each ) do
        task "outer_namespace::inner_namespace::#{task_name}"
      end

      it "should create the outer namespaces" do 
        Tasker::Namespace.all.map(&:name).should include( "outer_namespace" )
        Tasker::Namespace.all.map(&:name).should include( "outer_namespace::inner_namespace" )
      end
      it_should_behave_like( :a_task_in_a_nested_namespace )
    end

  end

  describe '#namespace' do
    let( :namespace_name ) { "dummy_namespace" }
    let( :namespace_options ) { { :foo => :bar } }
    let( :namespace_block ) { Proc.new { } }

    context "a top level namespace" do
      it "should add the namespace to Namespace.all" do
        expect { namespace( namespace_name, namespace_options, &namespace_block ) }.to change { Tasker::Namespace.all.size }.by(1)
        Tasker::Namespace.all.last.name.should == namespace_name
      end
    end

    context "nested namespaces" do
      shared_examples_for( :a_nested_namespace ) do
        it "should have the outer namespace" do
          Tasker::Namespace.all.map(&:name).should include( "second_namespace" )
        end

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
          ( Tasker::Namespace.all.map(&:name) - [ "second_namespace",
                                                  "outer_namespace",
                                                  "outer_namespace::middle_namespace",
                                                  "outer_namespace::middle_namespace::inner_namespace" ] ).should == []
        end
      end

      context "explicitly nested" do
        before( :each ) do
          namespace( "outer_namespace" ) do
            namespace( "middle_namespace" ) { namespace "inner_namespace"  }
          end

          namespace "second_namespace"
        end

        it_should_behave_like( :a_nested_namespace )
      end

      context "namespaced namespaces" do
        before( :each ) do
          namespace "outer_namespace::middle_namespace::inner_namespace" 
          namespace "second_namespace"
        end
        
        it_should_behave_like( :a_nested_namespace )

        it "should not re-create already existing namespaces" do
          namespace "outer_namespace::inner_namespace"
          outer_namespace = Tasker::Namespace.all.detect { |ns| ns.name == "outer_namespace" }
          
          namespace "outer_namespace"
          outer_namespace2 = Tasker::Namespace.all.detect { |ns| ns.name == "outer_namespace" }

          Tasker::Namespace.all.select { |ns| ns.name == "outer_namespace" }.size.should == 1
          outer_namespace.should === outer_namespace2
        end
      end

      context "nested and namespaced namespaces" do
        before( :each ) do
          namespace "outer_namespace" do
            namespace "middle_namespace::inner_namespace" 
          end
          namespace "second_namespace"
        end
        
        it_should_behave_like( :a_nested_namespace )
      end

      context "namespaced and nested namespaces" do
        before( :each ) do
          namespace "outer_namespace::middle_namespace" do
            namespace "inner_namespace"
          end
          namespace "second_namespace"
        end
        
        it_should_behave_like( :a_nested_namespace )
      end
    end
  end
end
