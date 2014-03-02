##
# Class: Machete::Control::Universe
#
require "berkshelf"
require "machete/control/cookbook"
require "machete/model"

module Machete
  module Control
    class Universe
      class << self
        #      def apply(envname, options={})
        #        raise MacheteError, "Undefined environment #{ envname }"
        # unless(@environment_controller.exist?(envname))
        #        upload(envname, options)
        #
        #        @universe.clusters.each do |name, cluster|
        #          cluster.client.node.all.each do |node|
        #            Machete::Log.info("Setting node #{ node.name }'s environment
        # to #{ envname } (#{ envname.gsub(".", "_") })")
        #            puts "Run List: #{node.run_list}"
        #            node.chef_environment = envname.gsub(".", "_")
        #            puts node
        #            node.save
        #          end
        #        end
        #      end
        def universe(name)
          unless(Machete::Model::Universe.collection.include?(name))
            raise Machete::Log.error("Universe #{ name } is not defined!")
          end

          Machete::Model::Universe.collection[name]
        end

        def upload(name, version=nil, options={})
          Machete::Control::Cookbook.install(version)

          Machete::Log.notify("Universe", "Uploading cookbooks to universe #{ name }")
          Machete::Control::Cookbook.upload(universe(name).clusters, options)
          Machete::Log.notify("Universe", "Cookbook upload complete")

          ## Upload Environment
          Machete::Control::Environment.upload(universe(name).clusters, version) unless(version.nil?)
        end

        def delete(name, cookbook, version=nil, options={})
          Machete::Log.notify("Universe", "Deleting cookbook #{cookbook} #{version.nil? ? "" : (version + " ") }from universe #{ @name }")
          Machete::Model::Cookbook.delete(universe(name).clusters, cookbook, version, options)
          Machete::Log.notify("Universe", "Cookbook deleted")
        end

        def delete_all(options={})
          Machete::Log.notify("Universe", "Deleting all cookbooks from universe #{ @name }")
          Machete::Model::Cookbook.delete_all(universe(name).clusters, options)
          Machete::Log.notify("Universe", "Cookbooks deleted")
        end
      end
    end
  end
end
