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

    def execute( options = {} )
      execute_task_chain( before_filters, "Unknown before task '%s' for task '#{@name}'" )
      @block.call( options ) if @block
      execute_task_chain( after_filters, "Unknown after task '%s' for task '#{@name}'" )
    end

    private
    def execute_task_chain( tasks, fail_message )
      tasks.each do |t|
        ns_segments = t.split( '::' )
        task_name = ns_segments.pop
        namespace_name = ns_segments.join( '::' )
        task = Tasker::Namespace.find_task_in_namespace( namespace_name, task_name )
        abort( fail_message % t ) unless task
        task.execute
      end
    end
  end
end
