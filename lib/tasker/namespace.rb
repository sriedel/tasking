module Tasker
  class Namespace
    attr_reader :name, :options, :block, :tasks

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

    def self.find_or_create( name, options = {}, &block )
      find_namespace( name ) || new( name, options, &block )
    end

    def initialize( name, options = {}, &block )
      @tasks = []
      @name = name
      @options = options
      @block = block
      
      self.class.add_namespace( self )
    end

    def execute( &alternate_block )
      block = alternate_block || @block
      block.call if block
    end

    def register_task( task )
      @tasks << task
    end

  end
end
