require "thor"
require "cleaver/control/universe"
require "cleaver/tasks/cookbook"
require "cleaver/tasks/environment"

module Cleaver
  module Tasks
    ##
    # Class Cleaver::Tasks::Base
    #
    class Base < Thor
      class_option :log_level, :type => :string, :aliases => :l
      class_option :cluster, :type => :array, :aliases => :c

      option :force, :type => :boolean, :aliases => :f
      option :search, :type => :string, :aliases => :s
      desc "apply VERSION", "Set universe nodes' environments to VERSION"
      def apply(name, version, *selected_nodes)
        say "Updating the following nodes to environment #{ version }:"
        nodes = find_and_print_nodes(name, options, selected_nodes.flatten)

        are_you_sure?("Continue updating nodes?")
        Control::Universe.apply(name, version, nodes, options) { |m| Cleaver.log.info(m) }
      rescue Cleaver::Error => e
        Cleaver.log.error(e)
      end

      option :force, :type => :boolean, :aliases => :f
      option :search, :type => :string, :aliases => :s
      desc "migrate FROM TO", "Set universe nodes' currently in environment FROM to environment TO"

      def migrate(name, from_version, to_version, *selected_nodes)
        say "Updating the following nodes from environment #{ from_version } to environment #{ to_version }:"
        options = self.options.dup
        options["search"] = "chef_environment:#{ from_version.gsub(".", "_") } #{ options["search"] }"

        nodes = find_and_print_nodes(name, options, selected_nodes.flatten)

        are_you_sure?("Continue updating nodes?")
        Control::Universe.apply(name, to_version, nodes, options) { |m| Cleaver.log.info(m) }
      end

      option :force, :type => :boolean, :aliases => :f
      option :no_freeze, :type => :boolean
      option :halt_on_frozen, :type => :boolean
      option :ignore_dependencies, :type => :boolean, :aliases => :i
      desc "upload UNIVERSE [VERSION]", "Upload an environment's cookbooks to the universe's chef servers"

      def upload(name, version = nil)
        options = self.options.dup
        options["freeze"] = !options["no_freeze"]

        Control::Universe.upload(name, version, options) { |m| Cleaver.log.info(m) }
      rescue Cleaver::Error => e
        Cleaver.log.error(e)
      end

      option :force, :type => :boolean, :aliases => :f
      desc "delete UNIVERSE COOKBOOK [VERSION]", "Remove a cookbook from the universe's chef servers"

      def delete(name, cookbook, version = nil)
        Control::Universe.delete(name, cookbook, version, options) { |m| Cleaver.log.info(m) }
      rescue Cleaver::Error => e
        Cleaver.log.error(e)
      end

      option :force, :type => :boolean, :aliases => :f
      desc "delete_all UNIVERSE", "Remove all cookbooks from the universe's chef servers"

      def delete_all(name)
        Control::Universe.delete_all(name, options) { |m| Cleaver.log.info(m) }
      rescue Cleaver::Error => e
        Cleaver.log.error(e)
      end

      register Cleaver::Tasks::Cookbook, :cookbook, "cookbook <COMMAND>", "Manage cookbooks"
      register Cleaver::Tasks::Environment, :env, "env <COMMAND>", "Manage environments"

      private

      def find_and_print_nodes(name, options, selected_nodes)
        clusters = Control::Universe.select_clusters(name, options)
        nodes = []

        clusters.each do |_, cluster|
          cluster_nodes = if options["search"]
            cluster.client.search(:node, options["search"])
          else
            cluster.nodes(selected_nodes)
          end

          unless cluster_nodes.nil? || cluster_nodes.empty?
            nodes.push(*cluster_nodes)

            say " -------- Cluster #{ _ } (#{ cluster.client.server_url }) --------"
            cluster_nodes.each do |node|
              say "   * #{ node.name } (#{ node.chef_environment })"
            end

            say " ----------------"
            puts ""
          end
        end

        nodes
      end

      def are_you_sure?(message = "Continue operation?")
        said = ask "#{ message } [y/n]"
        fail Cleaver::Error, "User aborted operation" unless said == "y"
      end
    end
  end
end
