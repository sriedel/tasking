#!/usr/bin/env ruby

module Tasker
  def task( name, options = {}, parent_namespace = nil, &block )
  end

  def namespace( name, options = {}, &block ) 
    namespace_segments = name.split( '::' )
    ns_name = @__parent_namespace == nil ? nil : 
              @__parent_namespace.last == nil ? nil :
              @__parent_namespace.last.name
    @__parent_namespace ||= []


    namespace_segments.each do |ns_segment|
      if ns_name
        ns_name += "::#{ns_segment}"
      else
        ns_name = ns_segment
      end
      @__parent_namespace << Tasker::Namespace.new( ns_name, options, &block )
    end
    @__parent_namespace.last.execute
    @__parent_namespace.pop
  end
end

require 'tasker/namespace'
require 'tasker/task'
