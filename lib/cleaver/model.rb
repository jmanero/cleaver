##
# Class: Cleaver::Model
#

require "json"
require "cleaver/model/helpers"
require "cleaver/model/cookbook"
require "cleaver/model/environment"
require "cleaver/model/universe"

module Cleaver
  ##
  # Cleaver Data Model
  ##
  module Model
    extend Cleaver::Model::Cookbook::DSL
    extend Cleaver::Model::Universe::DSL
    class << self
      extend Model::Helpers
      dispatch :cookbooks, Cleaver::Model::Cookbook, :collection
      dispatch :universes, Cleaver::Model::Universe, :collection
      def log_level(level)
        Cleaver.log.level = level
      end

      export :cookbooks, :universes

      def to_json
        JSON.pretty_generate(to_hash)
      end

      def from_file
        fail Cleaver::Error, "Configuration could not be read from #{ Cleaver.file })!" unless File.exist?(Cleaver.file)

        Model::Cookbook.initialize_filesystem
        Model::Environment.initialize_filesystem

        ## Load Cleaverfile DSL
        instance_exec do
          eval(IO.read(Cleaver.file), binding, Cleaver.file.to_s, 1)
        end
      end
    end
  end
end
