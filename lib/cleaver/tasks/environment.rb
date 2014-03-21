require "thor"
require "cleaver/control/environment"

module Cleaver
  module Tasks
    ##
    # Environment Tasks
    ##
    class Environment < Thor
      desc "list", "Print a list of the current versioned environments"
      def list
        Model::Environment.load_all.values.sort { |a, b| a.version <=> b.version }.each do |env|
          printf " %-24s %s\n", env.name, env.description
        end
      end

      desc "latest", "Print the latest environment name"

      def latest
        say Control::Environment.latest
      end

      option :force, :type => :boolean, :aliases => :f
      option :description, :type => :string, :aliases => :m
      option :prerelease_type, :type => :string, :default => "alpha", :aliases => :p
      desc "create [TYPE]", "Create a new semver environment"

      def create(type = :patch)
        Control::Environment.create(type, options) { |m| Cleaver.log.info(m) }
      rescue Cleaver::Error => e
        Cleaver.log.error(e)
      end
    end
  end
end
