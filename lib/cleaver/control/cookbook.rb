##
# Class: Cleaver::Control::Cookbook
#
require "berkshelf"
require "cleaver/model"

module Cleaver
  module Control
    ##
    # Cookbook Controller
    ##
    module Cookbook
      class << self
        def install(version = nil)
          yield "Installing cookbooks" if block_given?

          ## Get the right bookshelf
          cookbooks = if version.nil?
            Cleaver::Model::Cookbook
          else
            fail Cleaver::Error, "Environment #{ version } does not exist!" unless Model::Environment.exist?(version)
            yield "Using environment #{ version }" if block_given?
            Model::Environment.load(version).cookbook_shelf
          end

          ## Do black magic to fetch cookbooks
          resolver = Berkshelf::Resolver.new(cookbooks, :sources => cookbooks.sources)
          cookbooks.cache.push(*(resolver.resolve))

          yield "Cookbook install complete" if block_given?
        end

        def upload(clusters, options = {})
          filter_cookbooks(Cleaver::Model::Cookbook.cache, options).each do |cookbook|
            options = options.dup
            options["name"] = cookbook.cookbook_name

            ## Force upload cookbooks from local path
            options["force"] ||= Cleaver::Model::Cookbook.collection[cookbook.cookbook_name].location.is_a?(Berkshelf::PathLocation) rescue false

            clusters.each do |name, cluster|
              yield "Uploading #{ cookbook.cookbook_name } (#{ cookbook.version }) to #{ cluster.client.server_url } (#{ name })" if block_given?

              begin
                cluster.client.cookbook.upload(cookbook.path, options)
              rescue Ridley::Errors::FrozenCookbook
                raise Cleaver::Error, "Cookbook #{ cookbook.cookbook_name } is frozen on #{ cluster.client.server_url }" if options["halt_on_frozen"]
              end
            end
          end
        end

        def delete(clusters, cookbook, version = nil, options = {})
          clusters.each do |name, cluster|
            if version.nil?
              yield "Deleting all versions of #{ cookbook } from #{ cluster.server_url }" if block_given?
              cluster.client.cookbook.delete_all(cookbook, options)
            else
              yield "Deleting version #{ version } of #{ cookbook } from #{ cluster.server_url }" if block_given?
              cluster.client.cookbook.delete(cookbook, version, options)
            end
          end
        end

        def delete_all(clusters, options = {})
          clusters.each do |name, cluster|
            cluster.client.cookbook.all.each do |cookbook, versions|
              yield "Deleting all versions of #{ cookbook } from #{ cluster.server_url }" if block_given?
              cluster.client.cookbook.delete_all(cookbook, options)
            end
          end
        end

        def clear
          Cleaver::Model::Cookbook.storage_path.each_child { |c| FileUtils.rm_rf(c) }
          yield "Cookbook cache cleared" if block_given?
        end

        ## Boosted from https://github.com/berkshelf/berkshelf/blob/ <<
        # dc1638c979ded01123d3c0669118f00a96fb1cbf/lib/berkshelf/berksfile.rb#L676
        ## ref github/tags/3.0.0.beta5
        def filter_cookbooks(cookbooks, options = {})
          unless options["cookbook"].nil? || options["cookbook"].empty?
            explicit = cookbooks.select { |cookbook| options["cookbook"].include?(cookbook.cookbook_name) }

            unless options["ignore_dependencies"]
              explicit.each do |cookbook|
                cookbook.dependencies.each do |name, version|
                  explicit += cookbooks.select { |dependency| dependency.cookbook_name == name }
                end
              end
            end
            cookbooks = explicit.uniq
          end
          cookbooks
        end
      end
    end
  end
end
