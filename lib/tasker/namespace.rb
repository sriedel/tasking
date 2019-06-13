module Tasker
  class Namespace
    attr_reader :name, :options

    def self.namespaces
      @namespaces ||= {}
    end
    private_class_method :namespaces

    def self.all
      namespaces.values
    end

    def self.add_namespace( ns )
      namespaces[ns.name] = ns
    end

    def self.find_namespace( name )
      namespaces[name]
    end

    def self.find_task_in_namespace( ns_name, task_name )
      ns = find_namespace( ns_name )
      ns&.find_task( task_name )
    end

    def self.find_task( full_name )
      namespace_name, _, task_name = full_name.rpartition( '::' )

      Tasker::Namespace.find_task_in_namespace( namespace_name, task_name )
    end

    def self.find_or_create( name, options = {} )
      find_namespace( name ) || new( name, options )
    end

    def self.structure
      namespaces.map { |name, namespace| [ name, namespace.tasks.map(&:name)] }
    end

    def initialize( name, options = {} )
      @tasks = {}
      @name = name
      @options = options
      
      self.class.add_namespace( self )
    end

    def tasks
      @tasks.values
    end

    def parent_namespace
      parent_name, _, _ = @name.rpartition( '::' )

      parent_name.empty? ? nil : self.class.find_namespace( parent_name)
    end

    def execute( options = {}, &block )
      @options.merge!( options )
      block.call if block
    end

    def merge_options( options )
      @options.merge!( options )
    end

    def register_task( task )
      @tasks[task.name] = task
    end

    def unregister_task( task )
      @tasks.delete( task.name )
    end

    def find_task( name )
      @tasks[name]
    end
  end
end
