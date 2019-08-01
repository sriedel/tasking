module Tasking
  class Task
    attr_reader :name, :options, :block, :before_filters, :after_filters,
                :parent_namespace

    def initialize( name, parent_namespace, options = {}, &block )
      @name             = name
      @parent_namespace = parent_namespace
      @options          = options
      @block            = block
      @before_filters   = []
      @after_filters    = []
    end

    def add_before_filters( *filters )
      @before_filters.concat( filters.flatten )
    end

    def add_after_filters( *filters )
      @after_filters.concat( filters.flatten )
    end

    def execute( options = {} )
      total_options = @options.merge( options )
      execute_task_chain( before_filters, total_options, "Unknown before task '%s' for task '#{@name}'" )
      @block.call( resolve_options( total_options ) ) if @block
      execute_task_chain( after_filters, total_options, "Unknown after task '%s' for task '#{@name}'" )
    end

    private

    def resolve_options(options)
      options.transform_values { |v| v.respond_to?(:call) ? v.call(options) : v }
    end

    def execute_task_chain( tasks, options, fail_message )
      tasks.each do |t|
        task = task_lookup( t )
        abort( fail_message % t ) unless task
        task.execute(options)
      end
    end

    def task_lookup( name )
      name.slice!( 0, 2 ) if name.start_with?( '::' ) 
      Tasking::Namespace.find_task( name )
    end
  end
end
