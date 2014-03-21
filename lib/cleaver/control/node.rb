require "chef"
require "ridley"
require "thor"
require "cleaver/control/universe"
require "cleaver/model/universe"
require "securerandom"
require "cleaver/model/type"

module Cleaver
  module Control
    ##
    # Node Controller
    ##
    module Node
      class << self
        include Thor::Actions
        
        def provision(universe, cluster, type, options = {})
          Control::Universe.exist?(universe)
          fail Cleaver::Error, "Cluster #{ cluster } is not defined in universe #{ universe }" unless Model::Universe[universe].clusters.include?(cluster)
          fail Cleaver::Error, "Type #{ type } is not defined" unless Model::Type.collection.include?(type)

          ## Get entities
          cluster = Model::Universe[universe].clusters[cluster]
          type = Model::Type[type]

          ## Parameters
          serial = type.inc_serial
          run_list = type.run_list.dup
          run_list.unshift cluster.policy if cluster.policy

          ## Node Entity
          node = cluster.client.node.new
          node.name = "#{ type.name }-#{ serial }"
          node.run_list = run_list
          node.normal["cleaver"] = {
            "serial" => serial,
            "type" => type.name,
            "uuid" => SecureRandom.uuid
          }

          yield "Creating node and client #{ node.name } on cluster #{ cluster.name } (#{ cluster.server_url })" if block_given?

          ## Client Entity: Fucking Ridley is broken: {"error":["Field 'private_key' invalid"]}
          chef_client = Chef::REST.new(cluster.server_url, cluster.admin_client, cluster.admin_client_key)
          client = chef_client.post_rest("/clients", :name => node.name, :admin => false)
          
          node.save ## Save to Chef server
          type.save ## Save serial locally

          yeild "Defining VM for #{ node.name }" if block_given?
          
        end
      end
    end
  end
end
