module Tasker
  class Task
    attr_reader :name, :options, :block, :before_filters, :after_filters

    def initialize( name, options = {}, &block )
      @name = name
      @options = options
      @block = block
      @before_filters = []
      @after_filters = []
    end

    def add_before_filters( *filters )
      @before_filters.concat( filters.flatten )
    end

    def add_after_filters( *filters )
      @after_filters.concat( filters.flatten )
    end

    def execute
      before_filters.each do |bf|
        ns_segments = bf.split( '::' )
        task_name = ns_segments.pop
        namespace_name = ns_segments.join( '::' )
        before_task = Tasker::Namespace.find_task_in_namespace( namespace_name, task_name )
        abort( "Unknown before task '#{bf}' for task '#{@name}'" ) unless before_task
        before_task.execute
      end

      @block.call if @block

      after_filters.each do |af|
        ns_segments = af.split( '::' )
        task_name = ns_segments.pop
        namespace_name = ns_segments.join( '::' )
        after_task = Tasker::Namespace.find_task_in_namespace( namespace_name, task_name )
        abort( "Unknown before task '#{af}' for task '#{@name}'" ) unless after_task
        after_task.execute
      end
    end
  end
end
