##
# Class: Cleaver::Model::Cluster
#
require "ridley"
require "cleaver/model/entity"

module Cleaver
  module Model
    ##
    # Cluster Entity
    ##
    class Cluster < Cleaver::Model::Entity
      attribute :name
      attribute :server_url
      attribute :ssl_verify
      attribute :admin_client
      attribute :admin_client_key
      attribute :validation_client
      attribute :validation_client_key
      def initialize(name)
        @name = name
      end

      def client
        @client ||= Ridley.new(
        :server_url => server_url,
        :ssl => {  :verify => ssl_verify  },
        :client_name => admin_client,
        :client_key => admin_client_key
        )
      end

      def nodes(select = nil)
        query = select.nil? || select.empty? ? "*:*" : select.map { |s| "name:#{ s }"}.join(" ")
        client.search(:node, query)
      end

      export :name, :server_url, :admin_client,
      :admin_client_key, :validation_client, :validation_client_key
    end
  end
end
