#!/usr/bin/env ruby

module Tasker
  def task( name, options = {}, &block )
    abort( "Tasks with empty names are not allowed" ) if name.to_s == ""

    full_name = fully_qualified_name( name )
    namespace_name, task_name = split_task_from_namespace( full_name )

    if namespace_name == ""
      abort( "Task '#{name}' is not in a namespace" ) 
    else
      build_namespace_hierarchy( namespace_name )

      parent_namespace = Tasker::Namespace.find_namespace( namespace_name )
      existing_task = parent_namespace.find_task( task_name )

      parent_namespace.unregister_task( existing_task ) if existing_task

      task = Tasker::Task.new( task_name, options, &block )
      parent_namespace.register_task( task )
    end
  end

  def namespace( name, options = {}, &block ) 
    abort( "Namespaces with empty names are not allowed" ) if name.to_s == ""

    full_name = fully_qualified_name( name )
    parent_namespace_names, _ = split_task_from_namespace( full_name )
    build_namespace_hierarchy( parent_namespace_names )

    @__parent_namespace = Tasker::Namespace.find_or_create( full_name, options )
    @__parent_namespace.execute( &block )
    @__parent_namespace = nil
  end

  def execute( name )
    namespace_name, task_name = split_task_from_namespace( name )
    
    # Absolute search
    task = Tasker::Namespace.find_task_in_namespace( namespace_name, task_name )
  
    # or relative search
    if !task && @__parent_namespace
      full_namespace_name = fully_qualified_name( namespace_name )
      task = Tasker::Namespace.find_task_in_namespace( full_namespace_name, task_name )
    end
    
    if !task
      msg = "Unknown task '#{name}'"
      msg << "or #{fully_qualified_name( name )}" if @__parent_namespace
      abort( msg )
    end

    task.execute
  end
  alias_method :invoke, :execute
  alias_method :run, :execute

  private
  def fully_qualified_name( name )
    @__parent_namespace ? "#{@__parent_namespace.name}::#{name}" : name
  end

  def build_namespace_hierarchy( full_name ) 
    ns_name = nil

    full_name.split( '::' ).each do |ns_segment|
      if ns_name
        ns_name += "::#{ns_segment}"
      else
        ns_name = ns_segment
      end
      
      Tasker::Namespace.find_or_create( ns_name ) 
    end
  end

  def split_task_from_namespace( full_name )
    namespace_segments = full_name.split( '::' )
    task_name = namespace_segments.pop
    namespace_name = namespace_segments.join( '::' )

    return namespace_name, task_name
  end
end

require 'lib/tasker/namespace'
require 'lib/tasker/task'
