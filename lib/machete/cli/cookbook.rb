##
# Class Machete::CLI::Cookbook
#
require "machete/control/cookbook"

module Machete
  module CLI
    class Cookbook < Machete::CLI::Base
      def install(environment=nil)
        Machete::Control::Cookbook.install(environment)
      end

      def clear()
        Machete::Control::Cookbook.clear()
      end
    end
  end
end
