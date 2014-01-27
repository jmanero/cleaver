##
# Class: Machete::Control::Cookbook
#
require "berkshelf"

module Machete
  module Control
    class Cookbook
      def initialize(model)
        @clusters = model.clusters
        @cookbooks = model.cookbooks
      end

      def install
        resolver = Berkshelf::Resolver.new(@cookbooks, :sources => @cookbooks.sources)
        @cookbooks.cache = resolver.resolve
          
        Machete::Log.notify("Install Complete", "Cookbooks")
      end

      def upload(options={}, &block)
        install()
#        Machete::Log.notify("Starting Upload", "Cookbooks")

        filter_to_upload(@cookbooks.cache, options).each do |cookbook|
          @clusters.each do |cluster|
            next unless(options[:clusters].empty? || options[:clusters].include?(cluster.name))
            Machete::Log.info("Uploading #{ cookbook.cookbook_name } (#{ cookbook.version }) to #{ cluster.client.server_url }")

            begin
              cluster.client.cookbook.upload(cookbook.path, options.merge({ name: cookbook.cookbook_name }))
            rescue Ridley::Errors::FrozenCookbook => ex
              Machete::Log.debug("Cookbook #{ cookbook.cookbook_name } is frozen on #{ cluster.client.server_url }")
              if options[:halt_on_frozen]
                raise Berkshelf::FrozenCookbook, ex
              end
            end
          end
        end

#        Machete::Log.notify("Upload Complete", "Cookbooks")
      end

      def delete(cookbook, version=nil, options={})
        @clusters.each do |cluster|
          next unless(options[:clusters].empty? || options[:clusters].include?(cluster.name))

          if(version.nil?)
            Machete::Log.info("Deleting all versions of #{ cookbook } from #{ cluster.server_url }")
            cluster.client.cookbook.delete_all(cookbook, options)
          else
            Machete::Log.info("Deleting version #{ version } of #{ cookbook } from #{ cluster.server_url }")
            cluster.client.cookbook.delete(cookbook, version, options)
          end
        end
      end

      private

      ## Boosted from https://github.com/berkshelf/berkshelf/blob/master/ <<
      # lib/berkshelf/berksfile.rb#L676
      def filter_to_upload(cookbooks, options={})
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
