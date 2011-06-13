module Tasker
  class Task
    attr_reader :name, :options, :block

    def initialize( name, options = {}, &block )
      @name = name
      @options = options
      @block = block
    end
  end
end
