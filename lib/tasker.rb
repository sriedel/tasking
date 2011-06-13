#!/usr/bin/env ruby

module Tasker
  def task( name, options = {}, &block )
    namespace_segments = name.split( '::' )
    task_name = namespace_segments.pop
    namespace_name = namespace_segments.join( "::" )

    if namespace_name == ""
      abort( "Task '#{name}' is not in a namespace" ) if @__parent_namespace == nil
      task = Tasker::Task.new( name, options, &block )
      @__parent_namespace.register_task( task )
    else
      namespace( namespace_name ) do
        task( task_name, options, &block )
      end
    end
  end

  def namespace( name, options = {}, &block ) 
    namespace_segments = name.split( '::' )
    ns_name = @__parent_namespace == nil ? nil : @__parent_namespace.name

    namespace_segments.each do |ns_segment|
      if ns_name
        ns_name += "::#{ns_segment}"
      else
        ns_name = ns_segment
      end

      @__parent_namespace = Tasker::Namespace.new( ns_name, options, &block )
    end

    @__parent_namespace.execute
    @__parent_namespace = nil
  end

  def execute( task_name )
    namespace_segments = task_name.split( '::' )
    task_name = namespace_segments.pop
    namespace_name = namespace_segments.join( '::' )

    task = nil
    
    parent_namespace = Tasker::Namespace.all.detect { |ns| ns.name == namespace_name } 
    if parent_namespace
      task = parent_namespace.tasks.detect { |t| t.name == task_name }
    end

    if !task && @__parent_namespace
      namespace_name = @__parent_namespace.name + "::" + namespace_name
      parent_namespace = Tasker::Namespace.all.detect { |ns| ns.name == namespace_name } 
      if parent_namespace
        task = parent_namespace.tasks.detect { |t| t.name == task_name }
      end
    end
    
    if !task
      msg = "Unknown task '#{task_name}'"
      msg << "or #{@__parent_namespace.name + "::" + task_name}" if @__parent_namespace
      abort( msg )
    end

    task.execute
  end
  alias_method :invoke, :execute
end

require 'lib/tasker/namespace'
require 'lib/tasker/task'
