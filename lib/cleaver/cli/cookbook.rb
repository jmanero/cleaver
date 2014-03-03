##
# Class Cleaver::CLI::Cookbook
#
require "cleaver/control/cookbook"

module Cleaver
  module CLI
    class Cookbook < Cleaver::CLI::Base
      def install(environment=nil)
        Cleaver::Control::Cookbook.install(environment)
      end

      def clear()
        Cleaver::Control::Cookbook.clear()
      end
    end
  end
end
