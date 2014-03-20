##
# Class Cleaver::CLI::Cookbook
#
require "thor"
require "cleaver/control/cookbook"

module Cleaver
  module Tasks
    ##
    # Cookbook Tasks
    ##
    class Cookbook < Thor
      desc "install [VERSION]", "Install cookbooks into the local bookshelf"
      def install(environment = nil)
        Control::Cookbook.install(environment) { |m| Cleaver.log.info(m) }
      rescue Cleaver::Error => e
        Cleaver.log.error(e)
      end

      desc "clear", "Clear the local bookshelf"

      def clear
        Control::Cookbook.clear { |m| Cleaver.log.info(m) }
      rescue Cleaver::Error => e
        Cleaver.log.error(e)
      end
    end
  end
end
