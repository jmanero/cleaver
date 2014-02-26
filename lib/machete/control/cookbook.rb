##
# Class: Machete::Control::Cookbook
#
require "berkshelf"

module Machete
  module Control
    class Cookbook
      def initialize(model)
        @model = model
        @cookbooks = model.cookbooks
        @environments = model.environments
      end

      def install(envname=nil)
        Machete::Log.info("Using environment #{ envname }") unless(envname.nil?)
        Machete::Log.info("Installing cookbooks")

        cookbooks = if(envname && @environments.include?(envname))
          ## Create a new Cookbook collection for the specified environment
          collection = Machete::Model::Cookbooks.new(@model)
          @environments[envname].cookbooks.each do |name, cookbook|
            cookbook = cookbook.dup

            ## Fix attributes
            cookbook[:constraint] = "= #{cookbook.delete(:version)}"
            cookbook.delete(:name)

            collection.cookbook(name, nil, cookbook)
          end

          collection
        else
          @cookbooks
        end

        resolver = Berkshelf::Resolver.new(cookbooks, :sources => cookbooks.sources)
        @cookbooks.cache = resolver.resolve

        Machete::Log.notify("Cookbooks", "Cookbook install complete")
      end

      def upload(clusters, options={})
        filter_cookbooks(@cookbooks.cache, options).each do |cookbook|
          _options = options.dup
          _options[:name] = cookbook.cookbook_name

          ## Force cookbooks from local path
        _options[:force] ||= @cookbooks[cookbook.cookbook_name.to_sym].location.is_a?(Berkshelf::PathLocation) rescue false

          clusters.each do |name, cluster|
            next unless(options[:cluster].empty? || options[:cluster].include?(name))
            Machete::Log.info("Uploading #{ cookbook.cookbook_name } (#{ cookbook.version }) to #{ cluster.client.server_url } (#{ name })")

            begin
              cluster.client.cookbook.upload(cookbook.path, _options)
            rescue Ridley::Errors::FrozenCookbook => ex
              Machete::Log.debug("Cookbook #{ cookbook.cookbook_name } is frozen on #{ cluster.client.server_url }")
              if options[:halt_on_frozen]
                raise MacheteError, "Cookbook #{ cookbook.cookbook_name } is frozen on #{ cluster.client.server_url }"
              end
            end
          end
        end
      end

      def delete(clusters, cookbook, version=nil, options={})
        clusters.each do |name, cluster|
          next unless(options[:clusters].nil? || options[:clusters].empty? || options[:clusters].include?(name))

          if(version.nil?)
            Machete::Log.info("Deleting all versions of #{ cookbook } from #{ cluster.server_url }")
            cluster.client.cookbook.delete_all(cookbook, options)
          else
            Machete::Log.info("Deleting version #{ version } of #{ cookbook } from #{ cluster.server_url }")
            cluster.client.cookbook.delete(cookbook, version, options)
          end
        end
      end

      def delete_all(clusters, options={})
        clusters.each do |name, cluster|
          next unless(options[:clusters].nil? || options[:clusters].empty? || options[:clusters].include?(name))
          cluster.client.cookbook.all.each do |name, versions|
            Machete::Log.info("Deleting all versions of #{ name } from #{ cluster.server_url }")
            cluster.client.cookbook.delete_all(name, options)
          end
        end
      end

      def clear
        @cookbooks.storage_path.each_child {|c| FileUtils.rm_rf(c)}
        Machete::Log.info("Cookbook cache cleared")
      end

      private

      ## Boosted from https://github.com/berkshelf/berkshelf/blob/ <<
      # dc1638c979ded01123d3c0669118f00a96fb1cbf/lib/berkshelf/berksfile.rb#L676
      ## ref github/tags/3.0.0.beta5
      def filter_cookbooks(cookbooks, options={})
        unless options[:cookbooks].nil? || options[:cookbooks].empty?
          explicit = cookbooks.select { |cookbook| options[:cookbooks].include?(cookbook.cookbook_name) }

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
