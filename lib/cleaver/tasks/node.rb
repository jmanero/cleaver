require "thor"
require "cleaver/control/node"

module Cleaver
  module Tasks
    ##
    # Node Tasks
    ##
    class Node < Thor
      include Thor::Actions

      desc "provision UNIVERSE CLUSTER TYPE", "Provision a new node in the specified cluster"
      def provision(universe, cluster, type)
        Control::Node.provision(universe, cluster, type, options) { |m| Cleaver.log.info(m) }
      rescue Cleaver::Error => e
        Cleaver.log.error(e)
      end
    end
  end
end
