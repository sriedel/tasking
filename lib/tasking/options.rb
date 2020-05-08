module Tasking
  class Options
    attr_reader :options_hash

    def self.build( options )
      return options if options.is_a?(Tasking::Options)

      new( options )
    end

    def initialize(hash)
      @options_hash = hash
    end

    def [](key)
      resolve_value(options_hash[key])
    end

    def merge(other)
      self.class.new( options_hash.merge( extract_options_hash( other ) ) )
    end

    def merge!(other)
      options_hash.merge!( extract_options_hash( other ) )
      self
    end

    def ==(other)
      options_hash == extract_options_hash( other )
    end

    def materialized_hash
      options_hash.map do |key, value|
        [ key, resolve_value( value ) ]
      end.to_h
    end

    private

    def resolve_value( value )
      value.respond_to?( :call ) ? value.call(self) : value
    end

    def extract_options_hash(other)
      other.is_a?( self.class ) ? other.options_hash : other
    end
  end
end
