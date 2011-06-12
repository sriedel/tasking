#!/usr/bin/env ruby

module Tasker
  def task( name, options = {}, &block )
  end

  def namespace( name, options = {}, &block ) 
    Tasker::Namespace.new( name, options, &block ) 
  end
end

require 'tasker/namespace'
require 'tasker/task'
