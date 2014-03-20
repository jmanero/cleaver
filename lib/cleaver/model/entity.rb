require "cleaver/model/helpers"

module Cleaver
  module Model
    ##
    # Entity Base
    ##
    class Entity
      extend Cleaver::Model::Helpers
      class << self
        def collection
          @collection ||= Cleaver::Model::Collection.new
        end

        def [](name)
          collection[name]
        end

        def []=(name, value)
          collection[name] = value
        end
      end

      def complete
        self
      end

      def to_hash
        {}
      end

      def to_json
        JSON.pretty_generate(to_hash)
      end
    end

    ##
    # Collection
    ##
    class Collection < Hash
      extend Cleaver::Model::Helpers
      def [](name)
        super(name.to_s)
      end

      def []=(name, value)
        super(name.to_s, value)
      end

      def key?(name)
        super(name.to_s)
      end
      alias_method :include?, :key?

      def delete(name)
        super(name.to_s)
      end

      def to_hash
        Hash[map { |c| [c[0], c[1].to_hash] }]
      end
    end
  end
end
