##
# Class: Machete::Model::Universe
#
require "machete/model/cluster"

module Machete
  class Model
    class Universe < Machete::Model::Entity
      attribute :name

      ## Clusters
      attr_reader :clusters
      dispatch :cluster, :clusters
      def initialize(name, model)
        @name = name
        @model = model
        @clusters = Machete::Model::Clusters.new(self)
      end

      export :clusters
    end

    class Universes < Machete::Model::Collection
      def universe(name, &block)
        entity = Universe.new(name, @model)
        entity.instance_exec(&block) if(block)
        @entities[name] = entity.complete

        entity
      end
    end
  end
end
