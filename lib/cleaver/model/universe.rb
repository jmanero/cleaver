##
# Class: Cleaver::Model::Universe
#
require "cleaver/model/cluster"

module Cleaver
  module Model
    class Universe < Cleaver::Model::Entity
      class << self
        def universe(name, &block)
          entity = Universe.new(name)
          entity.instance_exec(&block) if(block)

          Universe.collection[name] = entity.complete
        end
      end

      module DSL
        def universe(*args, &block)
          Universe.universe(*args, &block)
        end
      end

      attribute :name
      attr_reader :clusters

      def cluster(name, &block)
        entity = Cluster.new(name)
        entity.instance_exec(&block) if(block)

        @clusters[name] = entity.complete
      end

      def initialize(name)
        @name = name
        @clusters = Cleaver::Model::Collection.new()
      end

      export :name, :clusters
    end
  end
end
