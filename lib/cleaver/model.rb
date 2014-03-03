##
# Class: Cleaver::Model
#

require "json"
require "cleaver/log"
require "cleaver/model/helpers"
require "cleaver/model/cookbook"
require "cleaver/model/environment"
require "cleaver/model/universe"

module Cleaver
  module Model
    extend Cleaver::Model::Cookbook::DSL
    extend Cleaver::Model::Universe::DSL
    class << self
      extend Cleaver::Model::Helpers
      dispatch :cookbooks, Cleaver::Model::Cookbook, :collection
      dispatch :universes, Cleaver::Model::Universe, :collection
      dispatch :log_level, Cleaver::Log, :level

      export :cookbooks, :universes
      def to_json
        JSON.pretty_generate(to_hash)
      end

      def from_file(name="Cleaverfile")
        raise CleaverError, "Configuration could not be read from #{ Cleaver.file })!" unless File.exist?(Cleaver.file)

        Cleaver::Model::Cookbook.initialize_filesystem
        Cleaver::Model::Environment.initialize_filesystem

        ## Load Cleaverfile DSL
        Cleaver::Model.instance_exec do
          eval(IO.read(Cleaver.file), binding, Cleaver.file.to_s, 1)
        end
        Cleaver::Log.info("Using #{ Cleaver.file }")
      end
    end
  end
end
