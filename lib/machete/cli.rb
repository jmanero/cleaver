##
# Class Machete::CLI
#
require "machete"
require "thor"

#require "thor-scmversion"

require "machete/cli/helpers"
require "machete/cli/cookbook"
require "machete/cli/environment"
require "machete/cli/universe"
require "machete/config"
require "machete/log"

module Machete
  module CLI
    class Tasks < Machete::CLI::Base
      option :log_level, :kind_of => String, :one_of => %w{debug info warn error}, :alias => :l
      register Machete::CLI::Cookbook, :cookbook, "cookbook <COMMAND>", "Manage cookbooks"
      register Machete::CLI::Environment, :environment, "environment <COMMAND>", "Manage environments"
      register Machete::CLI::Universe, :universe, "universe <name> <COMMAND>", "Manage universes"

      def initialize(*args)
        super(*args)
        Machete::Config.from_file
        Machete::Log.level(options[:log_level]) ## Override the Machetefile
      end

      def noop
        Machete::Log.debug("Nothing to see here...")
      end

      def config
        puts Machete.model.to_json
      end

    end
  end
end
