##
# Class: Machete::Model
#

require "json"
require "machete/config"
require "machete/log"
require "machete/model/helpers"
require "machete/model/cookbook"
require "machete/model/environment"
require "machete/model/universe"

Machete::Model::Cookbook.initialize_filesystem
Machete::Model::Environment.initialize_filesystem

module Machete
  class Model
    extend Machete::Model::Cookbook::DSL
    extend Machete::Model::Universe::DSL
    class << self
      extend Machete::Model::Helpers
      dispatch :cookbooks, Machete::Model::Cookbook, :collection
      dispatch :universes, Machete::Model::Universe, :collection
      dispatch :log_level, Machete::Log, :level

      export :cookbooks, :universes
      def to_json
        JSON.pretty_generate(to_hash)
      end
    end
  end
end
