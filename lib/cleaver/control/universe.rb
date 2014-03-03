##
# Class: Cleaver::Control::Universe
#
require "berkshelf"
require "cleaver/control/cookbook"
require "cleaver/model"

module Cleaver
  module Control
    module Universe
      class << self
        #      def apply(envname, options={})
        #        raise CleaverError, "Undefined environment #{ envname }"
        # unless(@environment_controller.exist?(envname))
        #        upload(envname, options)
        #
        #        @universe.clusters.each do |name, cluster|
        #          cluster.client.node.all.each do |node|
        #            Cleaver::Log.info("Setting node #{ node.name }'s environment
        # to #{ envname } (#{ envname.gsub(".", "_") })")
        #            puts "Run List: #{node.run_list}"
        #            node.chef_environment = envname.gsub(".", "_")
        #            puts node
        #            node.save
        #          end
        #        end
        #      end
        def universe(name)
          unless(Cleaver::Model::Universe.collection.include?(name))
            raise Cleaver::Log.error("Universe #{ name } is not defined!")
          end

          Cleaver::Model::Universe.collection[name]
        end

        def upload(name, version=nil, options={})
          Cleaver::Control::Cookbook.install(version)

          Cleaver::Log.notify("Universe", "Uploading cookbooks to universe #{ name }")
          Cleaver::Control::Cookbook.upload(universe(name).clusters, options)
          Cleaver::Log.notify("Universe", "Cookbook upload complete")

          ## Upload Environment
          Cleaver::Control::Environment.upload(universe(name).clusters, version) unless(version.nil?)
        end

        def delete(name, cookbook, version=nil, options={})
          Cleaver::Log.notify("Universe", "Deleting cookbook #{cookbook} #{version.nil? ? "" : (version + " ") }from universe #{ @name }")
          Cleaver::Model::Cookbook.delete(universe(name).clusters, cookbook, version, options)
          Cleaver::Log.notify("Universe", "Cookbook deleted")
        end

        def delete_all(options={})
          Cleaver::Log.notify("Universe", "Deleting all cookbooks from universe #{ @name }")
          Cleaver::Model::Cookbook.delete_all(universe(name).clusters, options)
          Cleaver::Log.notify("Universe", "Cookbooks deleted")
        end
      end
    end
  end
end
