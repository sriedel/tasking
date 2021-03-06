#!/usr/bin/env ruby

module Tasking
  def task( name, options = {}, &block )
    abort( "Tasks with empty names are not allowed" ) if name.to_s.empty?

    full_name = fully_qualified_name( name )
    namespace_name, task_name = split_task_from_namespace( full_name )

    abort( "Task '#{name}' is not in a namespace" ) if namespace_name.empty?

    build_namespace_hierarchy( namespace_name )

    parent_namespace = Tasking::Namespace.find_namespace( namespace_name )
    task = Tasking::Task.new( task_name, parent_namespace, options, &block )
    parent_namespace.register_task( task )
  end

  def namespace( name, options = {}, &block ) 
    abort( "Namespaces with empty names are not allowed" ) if name.to_s.empty?
    @__parent_namespace ||= []

    full_name = fully_qualified_name( name )
    parent_namespace_names, _ = split_task_from_namespace( full_name )
    build_namespace_hierarchy( parent_namespace_names )

    next_namespace = Tasking::Namespace.find_or_create( full_name, options )
    @__parent_namespace.push( next_namespace )
    next_namespace.execute( options, &block )
    @__parent_namespace.pop
  end

  def options( options ) 
    @__parent_namespace.last.merge_options( options )
  end

  def late_before( task_name, parent_namespace_name, *before_task_names )
    task = Tasking::Namespace.find_task_in_namespace( parent_namespace_name, task_name ) ||
           Tasking::Namespace.find_task( task_name ) 
    abort( "Unknown task '#{task_name}' in before filter" ) unless task

    task.add_before_filters( *before_task_names )
  end

  def late_after( task_name, parent_namespace_name, *after_task_names )
    task = Tasking::Namespace.find_task_in_namespace( parent_namespace_name, task_name ) ||
           Tasking::Namespace.find_task( task_name ) 
    abort( "Unknown task '#{task_name}' in after filter" ) unless task

    task.add_after_filters( *after_task_names )
  end

  def before( task_name, *before_task_names )
    @__late_evaluations ||= {}
    @__late_evaluations[:before] ||= []
    parent_namespace_name = @__parent_namespace.last&.name.to_s
    @__late_evaluations[:before] << [ task_name, parent_namespace_name, before_task_names.flatten ]
  end

  def after( task_name, *after_task_names )
    @__late_evaluations ||= {}
    @__late_evaluations[:after] ||= []
    parent_namespace_name = @__parent_namespace.last&.name.to_s
    @__late_evaluations[:after] << [ task_name, parent_namespace_name, after_task_names.flatten ]
  end

  def late_evaluations
    return unless @__late_evaluations
    @__late_evaluations.each_pair do |type, task_parameters|
      task_parameters.each do |( task_name, parent_namespace_name, args )|
        self.send( :"late_#{type}", task_name, parent_namespace_name, *args )
      end
    end
  end

  def execute( name, options = {} )
    if !@__subsequent_executions
      @__subsequent_executions = true
      late_evaluations
    end
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

    if name.start_with?( '::' ) 
      name.slice!( 0, 2 )
      return Tasking::Namespace.find_task( name )
    end

    if @__parent_namespace.last 
      full_name = "#{@__parent_namespace.last.name}::#{name}"
      task = Tasking::Namespace.find_task( full_name )
    end

    task || Tasking::Namespace.find_task( name )
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
    final_options = Tasking::Options.new({})

    walk_namespace_tree_to( full_task_name, :task ) do |ns_name|
      namespace = Tasking::Namespace.find_namespace( ns_name )
      final_options.merge!( namespace.options )
    end

    final_options.merge!( task.options )
  end

  def fully_qualified_name( name )
    @__parent_namespace&.last ? 
      "#{@__parent_namespace.last.name}::#{name}" : 
      name
  end

  def build_namespace_hierarchy( full_name ) 
    walk_namespace_tree_to( full_name ) do |ns_name|
      Tasking::Namespace.find_or_create( ns_name ) 
    end
  end

  def split_task_from_namespace( full_name )
    namespace_name, _, task_name = full_name.rpartition( '::' )

    [ namespace_name, task_name ]
  end
end

require_relative 'tasking/options'
require_relative 'tasking/namespace'
require_relative 'tasking/task'
