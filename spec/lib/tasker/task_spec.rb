require 'spec_helper'

describe Tasker::Task do
  describe "a new task" do
    let( :task_name ) { "dummy_task" }
    let( :task_options ) { { :foo => :bar } }
    let( :task_block ) { Proc.new { } }

    context "with only a name" do
      subject { Tasker::Task.new( task_name ) }

      its( :name ) { should == task_name }
      its( :options ) { should == {} }
      its( :block ) { should be_nil }
    end

    context "with all parameters" do
      subject { Tasker::Task.new( task_name, task_options, &task_block ) }

      its( :name ) { should == task_name }
      its( :options ) { should == task_options }
      its( :block ) { should == task_block }
    end
  end
end
