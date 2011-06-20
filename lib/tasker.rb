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

      task = Tasker::Task.new( task_name, parent_namespace, options, &block )
      parent_namespace.register_task( task )
    end
  end

  def namespace( name, options = {}, &block ) 
    abort( "Namespaces with empty names are not allowed" ) if name.to_s == ""
    @__parent_namespace ||= []

    full_name = fully_qualified_name( name )
    parent_namespace_names, _ = split_task_from_namespace( full_name )
    build_namespace_hierarchy( parent_namespace_names )

    next_namespace = Tasker::Namespace.find_or_create( full_name, options )
    @__parent_namespace.push next_namespace
    next_namespace.execute( options, &block )
    @__parent_namespace.pop
  end

  def options( options ) 
    @__parent_namespace.last.merge_options( options )
  end

  def before( task_name, *before_task_names )
    task = Tasker::Namespace.find_task( task_name )
    abort( "Unknown task '#{task_name}' in before filter" ) unless task

    task.add_before_filters( *before_task_names )
  end

  def after( task_name, *after_task_names )
    task = Tasker::Namespace.find_task( task_name )
    abort( "Unknown task '#{task_name}' in after filter" ) unless task

    task.add_after_filters( *after_task_names )
  end

  def execute( name, options = {} )
    task = task_lookup( name )
  
    if !task
      msg = "Unknown task '#{name}'"
      msg << " or #{fully_qualified_name( name )}" if @__parent_namespace.size > 0
      abort( msg )
    end

    namespace_hierarchy_options = gather_options_for( name, task )
    namespace_hierarchy_options.merge!( options )
    @__parent_namespace.push( task.parent_namespace )
    task.execute( namespace_hierarchy_options )
    @__parent_namespace.pop
  end
  alias_method :invoke, :execute
  alias_method :run, :execute

  private
  def task_lookup( name )
    @__parent_namespace ||= []
    task = nil

    if name.start_with?('::') 
      name.slice!(0,2)
      task = Tasker::Namespace.find_task( name )

    else
      if @__parent_namespace.last 
        full_name = @__parent_namespace.last.name + "::" + name
        task = Tasker::Namespace.find_task( full_name )
      end

      task ||= Tasker::Namespace.find_task( name )
    end

    task
  end

  def walk_namespace_tree_to( namespace_name, type = :namespace, &block )
    ns_segments = namespace_name.split( '::' )
    ns_segments.pop if type != :namespace

    current_ns_hierarchy_level = nil
    ns_segments.each do |segment|
      if current_ns_hierarchy_level == nil
        current_ns_hierarchy_level = segment
      else
        current_ns_hierarchy_level += "::#{segment}"
      end 

      block.call( current_ns_hierarchy_level )
    end
  end

  def gather_options_for( full_task_name, task )
    final_options = {}

    walk_namespace_tree_to( full_task_name, :task ) do |ns_name|
      namespace = Tasker::Namespace.find_namespace( ns_name )
      final_options.merge!( namespace.options )
    end

    final_options.merge!( task.options )
  end

  def fully_qualified_name( name )
    @__parent_namespace && @__parent_namespace.last ? 
      "#{@__parent_namespace.last.name}::#{name}" : 
      name
  end

  def build_namespace_hierarchy( full_name ) 
    walk_namespace_tree_to( full_name ) do |ns_name|
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
