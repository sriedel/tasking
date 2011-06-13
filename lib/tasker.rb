#!/usr/bin/env ruby

module Tasker
  def task( name, options = {}, &block )
    namespace_name, task_name = split_task_from_namespace( name )

    if namespace_name == ""
      abort( "Task '#{name}' is not in a namespace" ) unless @__parent_namespace

      task = Tasker::Task.new( name, options, &block )
      @__parent_namespace.register_task( task )

    else
      namespace( namespace_name ) do
        task( task_name, options, &block )
      end
    end
  end

  def namespace( name, options = {}, &block ) 
    ns_name = @__parent_namespace == nil ? nil : @__parent_namespace.name

    name.split( '::' ).each do |ns_segment|
      if ns_name
        ns_name += "::#{ns_segment}"
      else
        ns_name = ns_segment
      end
      
      @__parent_namespace = Tasker::Namespace.find_namespace( ns_name ) ||
                            Tasker::Namespace.new( ns_name, options, &block )
    end

    @__parent_namespace.execute
    @__parent_namespace = nil
  end

  def execute( task_name )
    namespace_name, task_name = split_task_from_namespace( task_name )
    
    # Try and find the task directly via it's namespaced name
    task = Tasker::Namespace.find_task_in_namespace( namespace_name, task_name )
  
    # or it may refer to a task within the invoking namespace
    if !task && @__parent_namespace
      namespace_name = @__parent_namespace.name + "::" + namespace_name
      task = Tasker::Namespace.find_task_in_namespace( namespace_name, task_name )
    end
    
    if !task
      msg = "Unknown task '#{task_name}'"
      msg << "or #{@__parent_namespace.name + "::" + task_name}" if @__parent_namespace
      abort( msg )
    end

    task.execute
  end
  alias_method :invoke, :execute
  alias_method :run, :execute

  private
  def split_task_from_namespace( full_name )
    namespace_segments = full_name.split( '::' )
    task_name = namespace_segments.pop
    namespace_name = namespace_segments.join( '::' )

    return namespace_name, task_name
  end
end

require 'lib/tasker/namespace'
require 'lib/tasker/task'
