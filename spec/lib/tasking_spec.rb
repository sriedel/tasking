require 'spec_helper'

describe Tasking do
  include Tasking

  before( :each ) do
    Tasking::Namespace.class_eval { @namespaces.clear if @namespaces }
  end

  describe "#before" do
    context "the order of execution" do
      before( :each ) do
        @executed = []

        namespace "foo" do
          task "before1" do
            @executed << "before1"
          end

          task "before2" do
            @executed << "before2"
          end

          task "target" do
            @executed << "target"
          end

        end
      end

      it "should execute the before filters before the main target" do
        before "foo::target", "foo::before1", "foo::before2"
        execute "foo::target"
        @executed.should == [ "before1", "before2", "target" ]
      end

      it "should accept the before filters as an array" do
        before "foo::target", [ "foo::before1", "foo::before2" ]
        execute "foo::target"
        @executed.should == [ "before1", "before2", "target" ]
      end

      it "should raise an error if the main task is unknown" do
        lambda do
          before "foo::unknown", "foo::before1" 
          execute "foo::unknown"
        end.should raise_error
      end

      it "should raise an error if a filter is unknown on execution" do
        before "foo::target", "foo::unknown"
        lambda { execute "foo::target" }.should raise_error
      end
    end

    context "late execution" do
      before( :each ) do
        namespace "outer" do
          before "my_task", "outer::first_task"

          task "first_task" do
            @executed << "outer::first_task"
          end

          task "my_task" do
            @executed << "outer::my_task"
          end
        end

        @executed = []
      end

      it "should not raise an error early on unresolved task names" do
        lambda { execute( "outer::my_task" ) }.should_not raise_error
      end

      it "should execute as expected" do
        execute( "outer::my_task" )
        @executed.should == [ "outer::first_task", "outer::my_task" ]
      end
    end

    context "the lookup" do
      before( :each ) do
        namespace "outer" do

          namespace "inner" do
            task( "relative" ) { @executed << "outer::inner::relative" }
          end

          task( "direct" ) { @executed << "outer::direct" }
          task( "mytask" ) { @executed << "outer::mytask" }
          before "mytask", "outer::direct", "::inner::absolute", "inner::fallback"
        end

        namespace "inner" do
          task( "absolute" ) { @executed << "inner::absolute" }
          task( "fallback" ) { @executed << "inner::fallback" }
        end
        
        @executed = []
      end

      it "should be able to do relative and absolute lookups" do
        execute "outer::mytask"
        @executed.should == [ "outer::direct", 
                              "inner::absolute",
                              "inner::fallback",
                              "outer::mytask" ]
      end
    end
  end

  describe "#after" do
    context "the order of execution" do
      before( :each ) do
        @executed = []

        namespace "foo" do
          task "after1" do
            @executed << "after1"
          end

          task "after2" do
            @executed << "after2"
          end

          task "target" do
            @executed << "target"
          end

        end
      end

      it "should execute the after filters after the main target" do
        after "foo::target", "foo::after1", "foo::after2"
        execute "foo::target"
        @executed.should == [ "target", "after1", "after2" ]
      end

      it "should accept the after filters as an array" do
        after "foo::target", [ "foo::after1", "foo::after2" ]
        execute "foo::target"
        @executed.should == [ "target", "after1", "after2" ]
      end

      it "should raise an error if the main task is unknown" do
        lambda do
          after "foo::unknown", "foo::after1" 
          execute "foo::unknown"
        end.should raise_error
      end

      it "should raise an error if a filter is unknown on execution" do
        after "foo::target", "foo::unknown"
        lambda { execute "foo::target" }.should raise_error
      end
    end

    context "the lookup" do
      before( :each ) do
        namespace "outer" do

          namespace "inner" do
            task( "relative" ) { @executed << "outer::inner::relative" }
          end

          task( "direct" ) { @executed << "outer::direct" }
          task( "mytask" ) { @executed << "outer::mytask" }
          after "mytask", "outer::direct", "::inner::absolute", "inner::fallback"
        end

        namespace "inner" do
          task( "absolute" ) { @executed << "inner::absolute" }
          task( "fallback" ) { @executed << "inner::fallback" }
        end
        
        @executed = []
      end

      it "should be able to do relative and absolute lookups" do
        execute "outer::mytask"
        @executed.should == [ "outer::mytask",
                              "outer::direct", 
                              "inner::absolute",
                              "inner::fallback" ]
      end
    end
  end

  describe "#execute" do
    context "the task options on execution" do
      before( :each ) do
        namespace( "outer", :outer_not_overridden              => :outer,
                            :outer_overridden_by_outer_options => :outer,
                            :outer_overridden_by_inner         => :outer,
                            :outer_overridden_by_inner_options => :outer,
                            :outer_overridden_by_task          => :outer,
                            :outer_overridden_by_execute       => :outer ) do

          options :outer_overridden_by_outer_options         => :outer_options,
                  :outer_options_not_overridden              => :outer_options,
                  :outer_options_overridden_by_inner         => :outer_options,
                  :outer_options_overridden_by_inner_options => :outer_options,
                  :outer_options_overridden_by_task          => :outer_options,
                  :outer_options_overridden_by_execute       => :outer_options

          namespace( "inner", :outer_overridden_by_inner         => :inner,
                              :outer_options_overridden_by_inner => :inner,
                              :inner_not_overridden              => :inner,
                              :inner_overridden_by_task          => :inner,
                              :inner_overridden_by_inner_options => :inner,
                              :inner_overridden_by_execute       => :inner ) do

            options :outer_overridden_by_inner_options         => :inner_options,
                    :outer_options_overridden_by_inner_options => :inner_options,
                    :inner_overridden_by_inner_options         => :inner_options,
                    :inner_options_not_overridden              => :inner_options,
                    :inner_options_overridden_by_task          => :inner_options,
                    :inner_options_overridden_by_execute       => :inner_options

            task( "my_task", :outer_overridden_by_task         => :task,
                             :outer_options_overridden_by_task => :task,
                             :inner_overridden_by_task         => :task,
                             :inner_options_overridden_by_task => :task,
                             :task_not_overridden              => :task,
                             :task_overridden_by_execute       => :task ) do |options|
              @set_options = options
            end
          end
        end
        execute( "outer::inner::my_task", :outer_overridden_by_execute => :exe,
                                          :outer_options_overridden_by_execute => :exe,
                                          :inner_overridden_by_execute => :exe,
                                          :inner_options_overridden_by_execute => :exe,
                                          :task_overridden_by_execute  => :exe,
                                          :execute_not_overridden      => :exe )
      end

      it "should get all options with the proper override sequence" do
        @set_options.should == { 
          :outer_not_overridden                      => :outer,
          :outer_overridden_by_outer_options         => :outer_options,
          :outer_overridden_by_inner                 => :inner,
          :outer_overridden_by_inner_options         => :inner_options,
          :outer_overridden_by_task                  => :task,
          :outer_overridden_by_execute               => :exe,
          :outer_options_not_overridden              => :outer_options,
          :outer_options_overridden_by_inner         => :inner,
          :outer_options_overridden_by_inner_options => :inner_options,
          :outer_options_overridden_by_task          => :task,
          :outer_options_overridden_by_execute       => :exe,
          :inner_not_overridden                      => :inner,
          :inner_overridden_by_inner_options         => :inner_options,
          :inner_overridden_by_task                  => :task,
          :inner_overridden_by_execute               => :exe,
          :inner_options_not_overridden              => :inner_options,
          :inner_options_overridden_by_task          => :task,
          :inner_options_overridden_by_execute       => :exe,
          :task_not_overridden                       => :task,
          :task_overridden_by_execute                => :exe,
          :execute_not_overridden                    => :exe }
      end
    end

    context "the task lookup order" do
      before( :each ) do
        namespace "outer" do
          namespace "inner" do
            task "my_task" do
              @executed << "outer::inner::my_task"
            end
          end

          task "relative_lookup" do
            execute "inner::my_task" 
          end

          task "fallback_lookup" do
            execute "inner::other_task"
          end

          task "absolute_lookup" do
            execute "::inner::my_task" 
          end
        end

        namespace "inner" do
          task "my_task" do
            @executed << "inner::my_task"
          end

          task "other_task" do
            @executed << "inner::other_task"
          end
        end
        
        @executed = []
      end

      it "should perform relative lookup first" do
        execute "outer::relative_lookup"
        @executed.last.should == "outer::inner::my_task"
      end

      it "should perform absolute lookups if the relative lookup didn't find anything" do
        execute "outer::fallback_lookup"
        @executed.last.should == "inner::other_task"
      end

      it "should perform absolute lookup when the name is prefixed by ::" do
        execute "outer::absolute_lookup"
        @executed.last.should == "inner::my_task"
      end
    end
  end

  describe "#options" do
    context "within a namespace" do
      before( :each ) do
        namespace "outer" do
          options :foo => :bar
        end
      end

      it "should get merged with the existing options" do
        ns = Tasking::Namespace.find_namespace( "outer" )
        ns.options.should == { :foo => :bar }
      end
    end

    context "within a nested namespace" do 
      before( :each ) do
        namespace "outer" do
          namespace "inner" do
            options :foo => :bar
          end
        end
      end

      it "should get merged with the options of the inner namespace" do
        ns = Tasking::Namespace.find_namespace( "outer::inner" )
        ns.options.should == { :foo => :bar }
      end

      it "should not change the options of the outer namespace" do
        ns = Tasking::Namespace.find_namespace( "outer" )
        ns.options.should == {}
      end
    end

    context "within a namespaced namespace" do
      before( :each ) do
        namespace "outer::inner" do
          options :foo => :bar
        end
      end

      it "should get merged with the options of the inner namespace" do
        ns = Tasking::Namespace.find_namespace( "outer::inner" )
        ns.options.should == { :foo => :bar }
      end

      it "should not change the options of the outer namespace" do
        ns = Tasking::Namespace.find_namespace( "outer" )
        ns.options.should == {}
      end
    end

    context "within a reopened namespace" do
      before( :each ) do
        namespace "outer" do
          options :foo => :bar, :baz => :quux
        end

        namespace "outer" do
          options :foo => :baz, :bla => :blubb
        end
      end

      it "should get merged with the existing options" do
        ns = Tasking::Namespace.find_namespace( "outer" )
        ns.options.should == { :foo => :baz, :baz => :quux, :bla => :blubb }
      end
    end
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
        registered_tasks = Tasking::Namespace.all.detect { |ns| ns.name == "outer_namespace" }.tasks
        registered_tasks.size.should == 1
        registered_tasks.first.name.should == task_name
      end
    end

    shared_examples_for( :a_task_in_a_nested_namespace ) do
      it "should add the task to the inner namespaces task list" do
        registered_tasks = Tasking::Namespace.all.detect { |ns| ns.name == "outer_namespace::inner_namespace" }.tasks
        registered_tasks.size.should == 1
        registered_tasks.first.name.should == task_name
        registered_tasks.first.parent_namespace.name.should == "outer_namespace::inner_namespace" 
      end

      it "should not add the task to the outer namespace task list" do
        registered_tasks = Tasking::Namespace.all.detect { |ns| ns.name == "outer_namespace" }.tasks
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
        Tasking::Namespace.all.map(&:name).should include( "outer_namespace" )
        Tasking::Namespace.all.map(&:name).should include( "outer_namespace::inner_namespace" )
      end
      it_should_behave_like( :a_task_in_a_nested_namespace )
    end

    context "within a namespaced name and a namespace" do
      before( :each ) do
        namespace "outer_namespace" do
          task "inner_namespace::#{task_name}"
        end
      end

      it "should create the outer namespaces" do 
        Tasking::Namespace.all.map(&:name).should include( "outer_namespace" )
        Tasking::Namespace.all.map(&:name).should include( "outer_namespace::inner_namespace" )
      end

      it_should_behave_like( :a_task_in_a_nested_namespace )
    end

    context "within a reopened namespace" do
      let( :old_options ) { { :foo => :bar } }
      let( :new_options ) { { :baz => :quux } }

      it "should overwrite the existing task" do
        namespace( "namespace" ) { task task_name, old_options }
        namespace( "namespace" ) { task task_name, new_options }

        ns = Tasking::Namespace.find_namespace( "namespace" )
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

        ns = Tasking::Namespace.find_namespace( namespace_name )
        ns.tasks.map(&:name).should include( "foo" )
        ns.tasks.map(&:name).should include( "bar" )
      end

      it "should merge the options of the two namespaces" do
        namespace( namespace_name, :foo => :bar, :baz => :quux )
        namespace( namespace_name, :foo => :baz, :bla => :blubb )

        ns = Tasking::Namespace.find_namespace( namespace_name )
        ns.options.should == { :foo =>:baz, :baz => :quux, :bla => :blubb }
      end
    end

    context "a top level namespace" do
      it "should add the namespace to Namespace.all" do
        expect { namespace( namespace_name, namespace_options, &namespace_block ) }.to change { Tasking::Namespace.all.size }.by(1)
        Tasking::Namespace.all.last.name.should == namespace_name
        Tasking::Namespace.all.last.parent_namespace.should be_nil
      end
    end

    context "nested namespaces" do
      shared_examples_for( :a_nested_namespace ) do
        it "should have the outer namespace" do
          ns = Tasking::Namespace.find_namespace( "second_namespace" )
          ns.should be_a( Tasking::Namespace )
          ns.parent_namespace.should be_nil
        end

        it "should have the outer namespace" do
          ns = Tasking::Namespace.find_namespace( "outer_namespace" )
          ns.should be_a( Tasking::Namespace )
          ns.options.should == {}
          ns.parent_namespace.should be_nil
        end
          
        it "should have the middle namespace" do
          ns = Tasking::Namespace.find_namespace( "outer_namespace::middle_namespace" )
          ns.should be_a( Tasking::Namespace )
          ns.options.should == {}
          ns.parent_namespace.should be_a( Tasking::Namespace )
          ns.parent_namespace.name.should == "outer_namespace"
        end
          
        it "should have the inner namespace" do
          ns = Tasking::Namespace.find_namespace( "outer_namespace::middle_namespace::inner_namespace" )
          ns.should be_a( Tasking::Namespace )
          ns.options.should == namespace_options
          ns.parent_namespace.should be_a( Tasking::Namespace )
          ns.parent_namespace.name.should == "outer_namespace::middle_namespace"
        end

        it "should have only the defined namespaces" do
          ( Tasking::Namespace.all.map(&:name) - [ "second_namespace",
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
          outer_namespace = Tasking::Namespace.all.detect { |ns| ns.name == "outer_namespace" }
          
          namespace "outer_namespace"
          outer_namespace2 = Tasking::Namespace.all.detect { |ns| ns.name == "outer_namespace" }

          Tasking::Namespace.all.select { |ns| ns.name == "outer_namespace" }.size.should == 1
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
        @executed.should == "foo::bar::my_task"

        execute( "foo::execute_absolute" )
        @executed.should == "foo::bar::my_task"
      end
    end

    context "when given a relative task name" do
      before( :each ) do
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

    context "when given options whose values are lambdas" do
      before(:each) do
        @resolved_options = nil

        namespace "option_resolver", :scalar_namespace_option => 'foo', 
                                     :lambda_namespace_option => lambda { |_opts| 'bar' } do
          task "task_with_options", :scalar_task_option => 'baz',
                                    :lambda_task_option => lambda { |_opts| 'quux' } do |resolved_options|
            @resolved_options = resolved_options
          end
        end
      end
      
      it 'should resolve the options as expected' do
        execute( 'option_resolver::task_with_options', :scalar_arg_option => 'bla',
                                                       :lambda_arg_option => lambda { |_opts| 'blubb' } )

        @resolved_options.should == { :scalar_namespace_option => 'foo',
                                      :lambda_namespace_option => 'bar',
                                      :scalar_task_option      => 'baz',
                                      :lambda_task_option      => 'quux',
                                      :scalar_arg_option       => 'bla',
                                      :lambda_arg_option       => 'blubb' }
                                      
      end
    end
  end
end
