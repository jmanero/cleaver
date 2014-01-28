##
# Class: Machete::Control::Universe
#
require "berkshelf"
require "machete/control/cookbook"

module Machete
  module Control
    class Universe
      def initialize(name, model)
        @name = name
        throw Machete::CLI::CLIError, "Universe #{ name } is not defined" unless(Machete.model.universes.includes?(name))

        @universe = Machete.model.universes[name]
        @cookbook_controller = Machete::Control::Cookbook.new(Machete.model)
      end

      def upload(environment, options={})
        @cookbook_controller.install(environment)
        Machete::Log.notify("Universe", "Uploading cookbooks to universe #{ @name }")
        @cookbook_controller.upload(@universe.clusters, options)
        Machete::Log.notify("Universe", "Cookbook upload complete")
      end

      def delete(cookbook, version=nil, options={})
        Machete::Log.notify("Universe", "Deleting cookbook #{cookbook}  version(s) #{version || "ALL"} from universe #{ @name }")
        @cookbook_controller.delete(@universe.clusters, cookbook, version, options)
        Machete::Log.notify("Universe", "Cookbook deleted")
      end

      def delete_all(options={})
        Machete::Log.notify("Universe", "Deleting all cookbooks from universe #{ @name }")
        @cookbook_controller.delete_all(@universe.clusters, options)
        Machete::Log.notify("Universe", "Cookbooks deleted")
      end
    end
  end
end
