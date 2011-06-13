#!/usr/bin/env ruby

module Tasker
  def task( name, options = {}, parent_namespace = nil, &block )
  end

  def namespace( name, options = {}, &block ) 
    parent_namespace = instance_variable_get( :@parent_namespace )
    namespace_segments = name.split( '::' )
    ns_name = parent_namespace == nil ? nil : parent_namespace.name

    namespace_segments.each do |ns_segment|
      if ns_name
        ns_name += "::#{ns_segment}"
      else
        ns_name = ns_segment
      end
      
      @parent_namespace = Tasker::Namespace.new( ns_name, options, &block )
      @parent_namespace.execute
    end
    @parent_namespace = nil
  end
end

require 'tasker/namespace'
require 'tasker/task'
