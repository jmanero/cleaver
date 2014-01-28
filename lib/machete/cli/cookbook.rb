##
# Class Machete::CLI::Cookbook
#
require "machete/control/cookbook"

module Machete
  module CLI
    class Cookbook < Machete::CLI::Base

      attr_reader :controller
      def initialize(*args)
        super(*args)
        @controller = Machete::Control::Cookbook.new(Machete.model)
      end

      def install(environment=nil)
        @controller.install(environment)
      end

      def clear()
        @controller.clear()
      end
    end
  end
end
