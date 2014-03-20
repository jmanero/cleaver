##
# Class: Cleaver::Model::Universe
#
require "cleaver/model/cluster"
require "cleaver/model/entity"

module Cleaver
  module Model
    ##
    # Universe Entoty
    ##
    class Universe < Cleaver::Model::Entity
      class << self
        def universe(name, &block)
          entity = Universe.new(name)
          entity.instance_exec(&block) if block

          Universe[name] = entity.complete
        end
      end

      ##
      # Cleaverfile DSL for Universe
      ##
      module DSL
        def universe(*args, &block)
          Universe.universe(*args, &block)
        end
      end

      attribute :name
      attr_reader :clusters

      def cluster(name, &block)
        entity = Cluster.new(name)
        entity.instance_exec(&block) if block

        @clusters[name] = entity.complete
      end

      def initialize(name)
        @name = name
        @clusters = Cleaver::Model::Collection.new
      end

      export :name, :clusters
    end
  end
end
