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
        raise MacheteError, "Universe #{ name } is not defined" unless(Machete.model.universes.includes?(name))

        @universe = Machete.model.universes[name]
        @cookbook_controller = Machete::Control::Cookbook.new(Machete.model)
        @environment_controller = Machete::Control::Environment.new(Machete.model)
      end

      def upload(envname=nil, options={})
        @cookbook_controller.install(envname)
        Machete::Log.notify("Universe", "Uploading cookbooks to universe #{ @name }")
        @cookbook_controller.upload(@universe.clusters, options)
        Machete::Log.notify("Universe", "Cookbook upload complete")

        ## Upload Environment
        @environment_controller.upload(@universe.clusters, envname) unless(envname.nil?)
      end

      def delete(cookbook, version=nil, options={})
        Machete::Log.notify("Universe", "Deleting cookbook #{cookbook} #{version.nil? ? "" : (version + " ") }from universe #{ @name }")
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
