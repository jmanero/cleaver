##
# Class Machete::CLI::Cluster
#
module Machete
  module CLI
    class Cluster < Thor
      desc "list", "List configured clusters"
      def list
        puts "  ------------ Clusters ------------"
        Machete.instance.clusters.each do |name, cluster|
          puts name
          printf "  %16s    %s\n", "Chef Server", cluster.server_url
          printf "  %16s    %s\n", "Client Name", cluster.admin_client
          puts ""
        end 
      end
    end
  end
end
