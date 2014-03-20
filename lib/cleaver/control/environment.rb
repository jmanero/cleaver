##
# Class: Cleaver::Control::Cookbook
#
require "thor"
require "thor-scmversion"
require "cleaver/control/cookbook"
require "cleaver/model/cookbook"
require "cleaver/model/environment"

module Cleaver
  module Control
    ##
    # Environment Controller
    ##
    module Environment
      include Thor::Actions
      class << self
        def create(type = :patch, options = {})
          options[:prerelease_type] ||= "alpha"

          Control::Cookbook.install ## Populate the Cache
          options["cookbooks"] = Model::Cookbook.current

          yield "Using current environment #{ current_version }"  if block_given?

          current_entity = Model::Environment.load(current_version.to_s)
          current_version.bump!(type, options)
          new_entity = Model::Environment.new(current_version.to_s, options)

          fail Cleaver::Error, "Cookbook versions have not changed!" if !options[:force] && new_entity == current_entity
          yield "Creating new #{ type } version #{ current_version }" if block_given?

          ## Use ThorSCMVersion to tag things
          current_version.write_version

          yield "Saving environment #{ current_version }" if block_given?
          new_entity.save

          run "git add #{ new_entity.relative_path }", :capture => true
          run "git commit -m 'Release #{ current_version }: #{ new_entity.description }'", :capture => true
          run "git tag -a -m 'Release #{ current_version }: #{ new_entity.description }' #{ current_version }", :capture => true
          run "git push", :capture => true
          run "git push --tags", :capture => true

          yield "Successfuly created environment #{ current_version }" if block_given?
        end

        def upload(clusters, name)
          fail Cleaver::Error, "Undefined environment #{ name }" unless Model::Environment.exist?(name)
          Model::Environment.load(name)

          clusters.each do |_, cluster|
            yield "Uploading environment #{ name } to #{ cluster.client.server_url } (#{ _ })" if block_given?
            begin
              cluster.client.environment.update(Model::Environment[name].chef_hash)
            rescue Ridley::Errors::HTTPNotFound
              cluster.client.environment.create(Model::Environment[name].chef_hash)
            end
          end
        end

        private

        def current_version
          @current_version ||= ThorSCMVersion.versioner.from_path
        end
      end
    end
  end
end
