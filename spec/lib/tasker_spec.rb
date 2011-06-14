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

    it "should disallow tasks with empty names" do
      lambda { namespace( "foo" ) { task "" } }.should raise_error
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

    context "within a reopened namespace" do
      let( :old_options ) { { :foo => :bar } }
      let( :new_options ) { { :baz => :quux } }

      it "should overwrite the existing task" do
        namespace( "namespace" ) { task task_name, old_options }
        namespace( "namespace" ) { task task_name, new_options }

        ns = Tasker::Namespace.find_namespace( "namespace" )
        ns.tasks.select { |t| t.name == task_name }.size.should == 1
        ns.tasks.detect { |t| t.name == task_name }.options.should == new_options  
      end
    end

  end

  describe '#namespace' do
    let( :namespace_name ) { "dummy_namespace" }
    let( :namespace_options ) { { :foo => :bar } }
    let( :namespace_block ) { Proc.new { } }

    it "should abort on an empty namespace name" do
      lambda { namespace( "" ) }.should raise_error
    end

    context "reopening namespaces" do
      it "subsequent namespaces should be executed as well" do
        namespace( namespace_name ) { task "foo" }
        namespace( namespace_name ) { task "bar" }

        ns = Tasker::Namespace.find_namespace( namespace_name )
        ns.tasks.map(&:name).should include( "foo" )
        ns.tasks.map(&:name).should include( "bar" )
      end
    end

    context "a top level namespace" do
      it "should add the namespace to Namespace.all" do
        expect { namespace( namespace_name, namespace_options, &namespace_block ) }.to change { Tasker::Namespace.all.size }.by(1)
        Tasker::Namespace.all.last.name.should == namespace_name
      end
    end

    context "nested namespaces" do
      shared_examples_for( :a_nested_namespace ) do
        it "should have the outer namespace" do
          ns = Tasker::Namespace.find_namespace( "second_namespace" )
          ns.should be_a( Tasker::Namespace )
        end

        it "should have the outer namespace" do
          ns = Tasker::Namespace.find_namespace( "outer_namespace" )
          ns.should be_a( Tasker::Namespace )
          ns.options.should == {}
        end
          
        it "should have the middle namespace" do
          ns = Tasker::Namespace.find_namespace( "outer_namespace::middle_namespace" )
          ns.should be_a( Tasker::Namespace )
          ns.options.should == {}
        end
          
        it "should have the inner namespace" do
          ns = Tasker::Namespace.find_namespace( "outer_namespace::middle_namespace::inner_namespace" )
          ns.should be_a( Tasker::Namespace )
          ns.options.should == namespace_options
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
            namespace( "middle_namespace" ) do
              namespace "inner_namespace", namespace_options
            end
          end

          namespace "second_namespace"
        end

        it_should_behave_like( :a_nested_namespace )
      end

      context "namespaced namespaces" do
        before( :each ) do
          namespace "outer_namespace::middle_namespace::inner_namespace", namespace_options
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
            namespace "middle_namespace::inner_namespace", namespace_options 
          end
          namespace "second_namespace"
        end
        
        it_should_behave_like( :a_nested_namespace )
      end

      context "namespaced and nested namespaces" do
        before( :each ) do
          namespace "outer_namespace::middle_namespace" do
            namespace "inner_namespace", namespace_options
          end
          namespace "second_namespace"
        end
        
        it_should_behave_like( :a_nested_namespace )
      end
    end
  end

  describe '#execute' do
    context "when given a fully qualified task name" do
      before( :each ) do
        namespace "foo" do
          task "execute_relative" do
            execute "bar::my_task"
          end

          task "execute_absolute" do
            execute "foo::bar::my_task"
          end

          namespace "bar" do
            task "my_task" do
              @executed = "foo::bar::my_task"
            end
          end
        end

        namespace "bar" do
          task "my_task" do
            @executed = "bar::my_task"
          end
        end
      end

      it "should execute the absolute task if found" do
        execute( "foo::execute_relative" )
        @executed.should == "bar::my_task"

        execute( "foo::execute_absolute" )
        @executed.should == "foo::bar::my_task"
      end
    end

    context "when given a relative task name" do
      before( :each ) do
        pending

        namespace "foo" do
          task "my_task" do
            execute "bar::my_task"
          end

          namespace "bar" do
            task "my_task" do
              @executed = "foo::bar::my_task"
            end
          end
        end

        namespace "bar" do
        end
      end

      it "should execute the relative task if no absolute task exists" do
        execute( "foo::my_task" )
        @executed.should == "foo::bar::my_task"
      end
    end

    context "when given a non-existant task name" do
      it "should abort with an error message" do
        lambda { execute "foo::bar" }.should raise_error
      end
    end
  end
end
