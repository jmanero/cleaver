##
# Class: Machete::Control::Cookbook
#
require "thor-scmversion"
require "machete/control/cookbook"
require "machete/model/cookbook"
require "machete/model/environment"

module Machete
  module Control
    class Environment
      class << self
        def create(type=:patch, options={})
          options[:prerelease_type] ||= "alpha"
          Machete::Control::Cookbook.install ## Populate the Cache
          options[:cookbooks] = Machete::Model::Cookbook.current

          Machete::Log.info("Creating new #{ type } version")
          Machete::Log.info("Using current environment #{ current_version }")

          current_entity = Machete::Model::Environment.load(current_version.to_s)
          current_version.bump!(type, options)
          new_entity = Machete::Model::Environment.new(current_version.to_s, options)

          if(!options[:force] && new_entity == current_entity)
            raise MacheteError, "Cookbook versions have not changed!"
          end

          ## Use ThorSCMVersion to tag things
          Machete::Log.debug("Creating new environment #{ current_version }")
          current_version.write_version

          Machete::Log.info("Saving environment #{ current_version }")
          new_entity.save

          Machete::Log.info("Trying to update git repository")
          Machete::Log.debug("git add #{ new_entity.relative_path }")
          ThorSCMVersion::ShellUtils.sh("git add #{ new_entity.relative_path }")
          Machete::Log.debug("git commit -m 'Release #{ current_version }: #{ new_entity.description }'")
          ThorSCMVersion::ShellUtils.sh("git commit -m 'Release #{ current_version }: #{ new_entity.description }'")
          Machete::Log.debug("git tag -a -m 'Release #{ current_version }: #{ new_entity.description }' #{ current_version }")
          ThorSCMVersion::ShellUtils.sh("git tag -a -m 'Release #{ current_version }: #{ new_entity.description }' #{ current_version }")
          ThorSCMVersion::ShellUtils.sh("git push || true")
          ThorSCMVersion::ShellUtils.sh("git push --tags || true")

          Machete::Log.notify("Environment", "Successfuly created environment #{ current_version }")
        end

        def upload(clusters, name)
          raise MacheteError, "Undefined environment #{ name }" unless(Machete::Model::Environment.exist?(name))
          environment = Machete::Model::Environment.load(name)

          clusters.each do |_, cluster|
            Machete::Log.info("Uploading environment #{ name } to #{ cluster.client.server_url } (#{ _ })")
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
