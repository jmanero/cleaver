##
# Class Cleaver::CLI
#
require "thor"

require "cleaver"
require "cleaver/cli/helpers"
require "cleaver/cli/cookbook"
require "cleaver/cli/environment"
require "cleaver/cli/universe"

module Cleaver
  module CLI
    class Tasks < Cleaver::CLI::Base
      option :log_level, :kind_of => String, :one_of => %w{debug info warn error}, :alias => :l

      register Cleaver::CLI::Cookbook, :cookbook, "cookbook <COMMAND>", "Manage cookbooks"
      register Cleaver::CLI::Environment, :environment, "environment <COMMAND>", "Manage environments"
      register Cleaver::CLI::Universe, :universe, "universe <name> <COMMAND>", "Manage universes"
      def initialize(*args)
        super(*args)
        Cleaver::Model.from_file
        Cleaver::Log.level(options[:log_level]) ## Override the Cleaverfile
      end

      def noop
        Cleaver::Log.debug("Nothing to see here...")
      end

      def config
        puts Cleaver::Model.to_json
      end

    end
  end
end
