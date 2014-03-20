##
# Class: Cleaver::Control::Universe
#
require "cleaver/control/cookbook"
require "cleaver/model"

module Cleaver
  module Control
    ##
    # Universe Controller
    ##
    module Universe
      class << self
        def apply(name, version, nodes, options = {}, &block)
          upload(name, version, options, &block)
          nodes.each do |node|
            underscored = version.gsub(".", "_")

            block.call("Setting node #{ node.name }'s environment to #{ version } (#{ underscored })") if block
            node.chef_environment = underscored
            node.save
          end
        end

        def upload(name, version = nil, options = {}, &block)
          clusters = select_clusters(name, options)
          Control::Cookbook.install(version, &block)

          block.call("Uploading cookbooks to universe #{ name }") if block
          Control::Cookbook.upload(clusters, options, &block)
          block.call("Cookbook upload complete") if block

          Control::Environment.upload(clusters, version, &block) unless version.nil?
        end

        def delete(name, cookbook, version = nil, options = {})
          clusters = select_clusters(name, options)

          yield "Deleting cookbook #{cookbook}" + (version.nil? ? "" : "@#{ version }") +
          " from universe #{ name }" if block_given?

          Control::Cookbook.delete(clusters, cookbook, version, options)
          yield "Cookbook deleted" if block_given?
        end

        def delete_all(options = {}, &block)
          clusters = select_clusters(name, options)

          yield "Deleting all cookbooks from universe #{ name }" if block_given?
          Control::Cookbook.delete_all(clusters, options)
          yield "Cookbooks deleted" if block_given?
        end

        def exist?(name)
          fail Cleaver::Error, "Universe #{ name } is not defined!"  unless Model::Universe.collection.include?(name)
        end

        def select_clusters(name, options = {})
          exist?(name)

          return Model::Universe[name].clusters if options["cluster"].nil? || options["cluster"].empty?
          Model::Universe[name].clusters.select { |_, cluster| options["cluster"].include?(_) }
        end
      end
    end
  end
end
