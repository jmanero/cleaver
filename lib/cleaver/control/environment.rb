##
# Class: Cleaver::Control::Cookbook
#
require "thor-scmversion"
require "cleaver/control/cookbook"
require "cleaver/model/cookbook"
require "cleaver/model/environment"

module Cleaver
  module Control
    module Environment
      class << self
        def create(type=:patch, options={})
          options[:prerelease_type] ||= "alpha"
          Cleaver::Control::Cookbook.install ## Populate the Cache
          options[:cookbooks] = Cleaver::Model::Cookbook.current

          Cleaver::Log.info("Using current environment #{ current_version }")

          current_entity = Cleaver::Model::Environment.load(current_version.to_s)
          current_version.bump!(type, options)
          new_entity = Cleaver::Model::Environment.new(current_version.to_s, options)

          if(!options[:force] && new_entity == current_entity)
            raise CleaverError, "Cookbook versions have not changed!"
          end
          Cleaver::Log.info("Creating new #{ type } version")

          ## Use ThorSCMVersion to tag things
          current_version.write_version

          Cleaver::Log.info("Saving environment #{ current_version }")
          new_entity.save

          Cleaver::Log.info("Trying to update git repository")
          Cleaver::Log.debug("git add #{ new_entity.relative_path }")
          ThorSCMVersion::ShellUtils.sh("git add #{ new_entity.relative_path }")
          
          Cleaver::Log.debug("git commit -m 'Release #{ current_version }: #{ new_entity.description }'")
          ThorSCMVersion::ShellUtils.sh("git commit -m 'Release #{ current_version }: #{ new_entity.description }'")
          
          Cleaver::Log.debug("git tag -a -m 'Release #{ current_version }: #{ new_entity.description }' #{ current_version }")
          ThorSCMVersion::ShellUtils.sh("git tag -a -m 'Release #{ current_version }: #{ new_entity.description }' #{ current_version }")
          
          ThorSCMVersion::ShellUtils.sh("git push || true")
          ThorSCMVersion::ShellUtils.sh("git push --tags || true")

          Cleaver::Log.notify("Environment", "Successfuly created environment #{ current_version }")
        end

        def upload(clusters, name)
          raise CleaverError, "Undefined environment #{ name }" unless(Cleaver::Model::Environment.exist?(name))
          environment = Cleaver::Model::Environment.load(name)

          clusters.each do |_, cluster|
            Cleaver::Log.info("Uploading environment #{ name } to #{ cluster.client.server_url } (#{ _ })")
            unless(environment.nil?)
              begin
                cluster.client.environment.update(environment.chef_hash)
              rescue Ridley::Errors::HTTPNotFound => e
                cluster.client.environment.create(environment.chef_hash)
              end
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
