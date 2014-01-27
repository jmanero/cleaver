##
# Class Machete::CLI
#
require "machete"
require "thor"
#require "thor-scmversion"

#require "machete/cli/cluster"
require "machete/cli/cookbook"
require "machete/cli/environment"
require "machete/config"
require "machete/log"

module Machete
  module CLI
    class Base < Thor
      class_option :log_level, :type => :string, :default => nil, :aliases => :l
      def initialize(*args)
        super(*args)

        begin
          Machete::Config.from_file(Dir.pwd)
          Machete::Log.level = options["log_level"] unless(options["log_level"].nil?)
        rescue Exception => e
          Machete::Log.error(e)
        end
      end

      desc "noop", "Nothing"

      def noop
        Machete::Log.debug("Nothing to see here...")
      end

      desc "config", "Print the loaded configuration for debugging/inspection"

      def config
        puts Machete.model.to_json
      end

      
      register Machete::CLI::Cookbook, "cookbook", "cookbook <COMMAND>", "Manage cookbook"
      register Machete::CLI::Environment, "environment", "environment <COMMAND>", "Manage environments"
#      register ThorSCMVersion::Tasks, "version", "version <COMMAND>", "Manage environment versioning"
    end
  end
end
