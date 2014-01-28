##
# Class: Machete::Control::Cookbook
#
require "thor-scmversion"

module Machete
  module Control
    class Environment
      def initialize(model)
        @cookbooks = model.cookbooks
        @clusters = model.clusters
        @environments = model.environments

        @cookbook_controller = Machete::Control::Cookbook.new(Machete.model)
      end

      def current_version
        @current_version ||= ThorSCMVersion.versioner.from_path
      end

      def create(type=:patch, options={})
        options[:prerelease_type] ||= "alpha"
        @cookbook_controller.install ## Populate the Cache
        options[:versions] = @cookbooks.versions

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
        Machete::Log.debug("git add #{ new_entity.git_path }")
        ThorSCMVersion::ShellUtils.sh("git add #{ new_entity.git_path }")
        Machete::Log.debug("git commit -m 'Release #{ current_version }: #{ new_entity.description }'")
        ThorSCMVersion::ShellUtils.sh("git commit -m 'Release #{ current_version }: #{ new_entity.description }'")
        Machete::Log.debug("git tag -a -m 'Release #{ current_version }: #{ new_entity.description }' #{ current_version }")
        ThorSCMVersion::ShellUtils.sh("git tag -a -m 'Release #{ current_version }: #{ new_entity.description }' #{ current_version }")
        ThorSCMVersion::ShellUtils.sh("git push || true")
        ThorSCMVersion::ShellUtils.sh("git push --tags || true")

        Machete::Log.notify("Environment", "Successfuly created environment #{ current_version }")
        @environments.environment(current_version.to_s, new_entity)
      end
    end
  end
end
