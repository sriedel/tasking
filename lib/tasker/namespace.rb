module Tasker
  class Namespace
    attr_reader :name, :options, :tasks

    def self.all
      @namespaces ||= []
    end

    def self.add_namespace( ns )
      @namespaces ||= []
      @namespaces << ns
    end

    def self.find_namespace( name )
      all.detect { |ns| ns.name == name }
    end

    def self.find_task_in_namespace( ns_name, task_name )
      ns = find_namespace( ns_name )
      ns ? ns.tasks.detect { |t| t.name == task_name } : nil
    end

    def self.find_or_create( name, options = {} )
      find_namespace( name ) || new( name, options )
    end

    def initialize( name, options = {} )
      @tasks = []
      @name = name
      @options = options
      
      self.class.add_namespace( self )
    end

    def execute( &block )
      block.call if block
    end

    def register_task( task )
      @tasks << task
    end

    def unregister_task( task )
      @tasks.delete( task )
    end

    def find_task( name )
      @tasks.detect { |t| t.name == name }
    end

  end
end
