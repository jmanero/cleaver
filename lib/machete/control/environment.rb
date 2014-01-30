##
# Class: Machete::Control::Cookbook
#
require "thor-scmversion"

module Machete
  module Control
    class Environment
      def initialize(model)
        @cookbooks = model.cookbooks
        @environments = model.environments

        @cookbook_controller = Machete::Control::Cookbook.new(Machete.model)
      end

      def create(type=:patch, options={})
        options[:prerelease_type] ||= "alpha"
        @cookbook_controller.install ## Populate the Cache
        options[:cookbooks] = @cookbooks.current

        Machete::Log.info("Creating new #{ type } version")
        Machete::Log.debug("Using current environment #{ current_version }")

        current_entity = @environments[current_version.to_s]

        current_version.bump!(type, options)
        new_entity = Machete::Model::Environment.new(@environments, current_version.to_s, options)

        if(!options[:force] && new_entity == current_entity)
          Machete::Log.error("Cookbook versions have not changed! Aborting.")
          return
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
        @environments.environment(current_version.to_s, new_entity)
      end

      def upload(clusters, envname)
        raise MacheteError, "Undefined environment #{ envname }" unless(@environments.includes?(envname))
        env = @environments[envname]

        clusters.each do |name, cluster|
          Machete::Log.info("Uploading environment #{ envname } to #{ cluster.client.server_url } (#{ name })")
          unless(env.nil?)
            begin
              cluster.client.environment.update(env.chef_hash)
            rescue Ridley::Errors::HTTPNotFound => e
              cluster.client.environment.create(env.chef_hash)
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
