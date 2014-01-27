##
# Class: Machete::Control::Cookbook
#
module Machete
  module Control
    class Environment
      def initialize(model)
        @cookbooks = model.cookbooks
        @clusters = model.clusters
        @environments = model.environments

        @cookbook_controller = Machete::Control::Cookbook.new(Machete.model)
      end

      def create(type=:patch, pre=:alpha, options={})
        @cookbook_controller.install ## Populate the Cache
        options[:versions] = @cookbooks.versions
        @environments.environment("foo", options)
      end
    end
  end
end
