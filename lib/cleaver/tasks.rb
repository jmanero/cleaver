require "colorize"
require "thor"
require "cleaver/control/universe"
require "cleaver/tasks/cookbook"
require "cleaver/tasks/environment"
require "cleaver/tasks/node"

module Cleaver
  module Tasks
    ##
    # Class Cleaver::Tasks::Base
    #
    class Base < Thor
      class_option :log_level, :type => :string, :aliases => :l
      class_option :cluster, :type => :array, :aliases => :c

      ##
      # Show nodes in the universe
      ##
      desc "show UNIVERSE", "Show all nodes in the universe"
      def show(name)
        find_and_print_nodes(name)
      rescue Cleaver::Error => e
        Cleaver.log.error(e)
      end

      ##
      # Set a collection of nodes' environments
      ##
      option :force, :type => :boolean, :aliases => :f
      option :search, :type => :string, :aliases => :s
      desc "apply UNIVERSE VERSION", "Set universe nodes' environments to VERSION"

      def apply(name, version, *selected_nodes)
        Control::Universe.exist?(name)

        say "Updating the following nodes to environment #{ version }:"
        nodes = find_and_print_nodes(name, options, selected_nodes.flatten)

        are_you_sure?("Continue updating nodes?") unless options["force"]
        Control::Universe.apply(name, version, nodes, options) { |m| Cleaver.log.info(m) }
      rescue Cleaver::Error => e
        Cleaver.log.error(e)
      end

      ##
      # Migrate a collection of nodes from one environment to another
      ##
      option :force, :type => :boolean, :aliases => :f
      option :search, :type => :string, :aliases => :s
      desc "migrate UNIVERSE FROM TO", "Set universe nodes' currently in environment FROM to environment TO"

      def migrate(name, from_version, to_version, *selected_nodes)
        Control::Universe.exist?(name)

        say "Updating the following nodes from environment #{ from_version } to environment #{ to_version }:"
        options = self.options.dup
        options["search"] = "chef_environment:#{ from_version.gsub(".", "_") } #{ options["search"] }"

        nodes = find_and_print_nodes(name, options, selected_nodes.flatten)

        are_you_sure?("Continue updating nodes?") unless options["force"]
        Control::Universe.apply(name, to_version, nodes, options) { |m| Cleaver.log.info(m) }
      end

      ##
      # Upload cookbooks and environments to the chef servers
      ##
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

      ##
      # Delete a cookbook from the chef servers
      ##
      option :force, :type => :boolean, :aliases => :f
      desc "delete UNIVERSE COOKBOOK [VERSION]", "Remove a cookbook from the universe's chef servers"

      def delete(name, cookbook, version = nil)
        Control::Universe.exist?(name)

        Cleaver.log.info("Deleting cookbook #{cookbook}" + (version.nil? ? "" : "@#{ version }") + " from universe #{ name }")
        are_you_sure?("Continue deleting cookbook(s)?") unless options["force"]

        Control::Universe.delete(name, cookbook, version, options) { |m| Cleaver.log.info(m) }
        Cleaver.log.info("Cookbook deleted")
      rescue Cleaver::Error => e
        Cleaver.log.error(e)
      end

      ##
      # !!! Delete all cookbooks from the chef servers
      ##
      option :force, :type => :boolean, :aliases => :f
      desc "delete_all UNIVERSE", "Remove all cookbooks from the universe's chef servers"

      def delete_all(name)
        Control::Universe.exist?(name)

        Cleaver.log.info("Deleting all cookbooks from universe #{ name }")
        are_you_sure?("Continue deleting all cookbooks?") unless options["force"]

        Control::Universe.delete_all(name, options) { |m| Cleaver.log.info(m) }
        Cleaver.log.info("Cookbooks deleted")
      rescue Cleaver::Error => e
        Cleaver.log.error(e)
      end

      ## Register Submodules
      register Cleaver::Tasks::Cookbook, :cookbook, "cookbook <COMMAND>", "Manage cookbooks"
      register Cleaver::Tasks::Environment, :env, "env <COMMAND>", "Manage environments"
      register Cleaver::Tasks::Node, :node, "node UNIVERSE CLUSTER <COMMAND>", "Manage environments"

      private

      def find_and_print_nodes(name, options = {}, selected_nodes = [])
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

            say " -------- Cluster #{ _ } (#{ cluster.client.server_url }) --------".white
            printf "   %-24s %-16s %-12s %-18s %s\n".blue, "Node Name", "Version", "Type", "Last Checkin", "Run List"
            cluster_nodes.sort { |a, b| a.name <=> b.name }.each do |node|
              type = node["normal"]["cleaver"]["type"] rescue nil
              last_run, color = calculate_last_run(node["automatic"]["ohai_time"])
              run_list = node["run_list"].join(", ")

              printf "   %-24s %-16s %-12s %-18s %s\n".send(color), node.name, node.chef_environment, type, last_run, run_list
            end

            say " ----------------".white
            puts ""
          end
        end

        nodes
      end

      def are_you_sure?(message = "Continue operation?")
        said = ask "#{ message } [y/n]"
        fail Cleaver::Error, "User aborted operation" unless said == "y"
      end

      ### https://github.com/opscode/chef/blob/master/lib/chef/knife/status.rb
      def calculate_last_run(ohai_time)
        hours, minutes, seconds = time_difference_in_hms(ohai_time)
        interval = ""
        interval += "#{ hours }h " unless hours == 0
        interval += "#{ minutes }m " unless hours == 0 && minutes == 0
        interval += "#{ seconds }s"

        color = case
          when hours >= 1 then :red
          when minutes >= 10 then :yellow
          else :green
        end

        [interval, color]
      end

      def time_difference_in_hms(unix_time)
        now = Time.now.to_i
        difference = now - unix_time.to_i
        hours = (difference / 3600).to_i
        difference = difference % 3600
        minutes = (difference / 60).to_i
        seconds = (difference % 60)

        [hours, minutes, seconds]
      end
    end
  end
end
