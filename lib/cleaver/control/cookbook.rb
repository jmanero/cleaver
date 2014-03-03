##
# Class: Cleaver::Control::Cookbook
#
require "berkshelf"
require "cleaver/model"

module Cleaver
  module Control
    module Cookbook
      class << self
        def install(version=nil)
          Cleaver::Log.info("Installing cookbooks")

          cookbooks = unless(version.nil?)
            unless(Cleaver::Model::Environment.exist?(version))
              return Cleaver::Log.error("Environment #{ version } does not exist!")
            end

            Cleaver::Log.info("Using environment #{ version }")
            Cleaver::Model::Environment.load(version).cookbook_shelf
          else
            Cleaver::Model::Cookbook
          end

          resolver = Berkshelf::Resolver.new(cookbooks, :sources => cookbooks.sources)
          cookbooks.cache.push(*(resolver.resolve))

          Cleaver::Log.notify("Cookbooks", "Cookbook install complete")
        end

        def upload(clusters, options={})
          filter_cookbooks(Cleaver::Model::Cookbook.cache, options).each do |cookbook|
            _options = options.dup
            _options[:name] = cookbook.cookbook_name

            ## Force cookbooks from local path
            _options[:force] ||= Cleaver::Model::Cookbook.collection[cookbook.cookbook_name].location.is_a?(Berkshelf::PathLocation) rescue false

            filter_clusters(clusters, options).each do |name, cluster|
              Cleaver::Log.info("Uploading #{ cookbook.cookbook_name } (#{ cookbook.version }) to #{ cluster.client.server_url } (#{ name })")

              begin
                cluster.client.cookbook.upload(cookbook.path, _options)
              rescue Ridley::Errors::FrozenCookbook => ex
                Cleaver::Log.debug("Cookbook #{ cookbook.cookbook_name } is frozen on #{ cluster.client.server_url }")
                if options[:halt_on_frozen]
                  raise CleaverError, "Cookbook #{ cookbook.cookbook_name } is frozen on #{ cluster.client.server_url }"
                end
              end
            end
          end
        end

        def delete(clusters, cookbook, version=nil, options={})
          filter_clusters(clusters, options).each do |name, cluster|
            if(version.nil?)
              Cleaver::Log.info("Deleting all versions of #{ cookbook } from #{ cluster.server_url }")
              cluster.client.cookbook.delete_all(cookbook, options)
            else
              Cleaver::Log.info("Deleting version #{ version } of #{ cookbook } from #{ cluster.server_url }")
              cluster.client.cookbook.delete(cookbook, version, options)
            end
          end
        end

        def delete_all(clusters, options={})
          filter_clusters(clusters, options).each do |name, cluster|
            cluster.client.cookbook.all.each do |name, versions|
              Cleaver::Log.info("Deleting all versions of #{ name } from
         #{ cluster.server_url }")
              cluster.client.cookbook.delete_all(name, options)
            end
          end
        end

        def clear
          Cleaver::Model::Cookbook.storage_path.each_child {|c| FileUtils.rm_rf(c)}
          Cleaver::Log.info("Cookbook cache cleared")
        end

        def filter_clusters(clusters, options={})
          return clusters if(options[:cluster].nil? || options[:cluster].empty?)

          _clusters = {}
          options[:cluster].each do |name|
            _clusters[name.to_sym] = clusters[name] if(clusters.include?(name))
          end

          _clusters
        end

        ## Boosted from https://github.com/berkshelf/berkshelf/blob/ <<
        # dc1638c979ded01123d3c0669118f00a96fb1cbf/lib/berkshelf/berksfile.rb#L676
        ## ref github/tags/3.0.0.beta5
        def filter_cookbooks(cookbooks, options={})
          unless options[:cookbook].nil? || options[:cookbook].empty?
            explicit = cookbooks.select { |cookbook| options[:cookbook].include?(cookbook.cookbook_name) }

            unless(options[:ignore_dependencies])
              explicit.each do |cookbook|
                cookbook.dependencies.each do |name, version|
                  explicit += cookbooks.select { |cookbook| cookbook.cookbook_name == name }
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
