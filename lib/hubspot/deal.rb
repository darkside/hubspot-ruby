require 'hubspot/utils'
require 'httparty'

module Hubspot
  #
  # HubSpot Deals API
  #
  # {http://developers.hubspot.com/docs/methods/deals/deals_overview}
  #
  class Deal

    attr_reader :properties
    attr_reader :portal_id
    attr_reader :deal_id
    attr_reader :company_ids
    attr_reader :vids

    CREATE_DEAL_PATH = "/deals/v1/deal"
    DEAL_PATH = "/deals/v1/deal/:deal_id"
    RECENT_UPDATED_PATH = "/deals/v1/deal/recent/modified"

    def initialize(response_hash)
      @portal_id = response_hash["portalId"]
      @deal_id = response_hash["dealId"]
      associations = response_hash["associations"]
      if associations.present?
        @company_ids = associations["associatedCompanyIds"]
        @vids = associations["associatedVids"]
      end
      @properties = properties_to_hash(response_hash["properties"])
    end

    delegate :camelize_hash, :hash_to_properties, :properties_to_hash, :connection, :get_json,
      :post_json, :put_json, :delete_json, to: :class

    class << self
      delegate :camelize_hash, :hash_to_properties, :properties_to_hash, to: Utils
      delegate :connection, to: Hubspot
      delegate :get_json, :post_json, :put_json, :delete_json, to: :connection

      # Creates a deal in hubspot
      # @raise [Hubspot::RequestError] if the response isn't a success
      # @return [Hubspot::Deal] the created deal
      def create!(portal_id, company_ids, vids, params={})
        associations_hash = {"portalId" => portal_id, "associations" => { "associatedCompanyIds" => company_ids, "associatedVids" => vids}}
        post_data = associations_hash.merge({ properties: hash_to_properties(params, key_name: "name") })
        response = post_json(CREATE_DEAL_PATH, body: post_data)
        new(response)
      end

      def update!(deal_id, params)
        _params = { deal_id: deal_id }
        post_data = { properties: hash_to_properties(params, key_name: "name") }
        response = put_json(DEAL_PATH, params: _params, body: post_data)
        new(response)
      end

      def find(deal_id)
        _params = {deal_id: deal_id}
        response = get_json(DEAL_PATH, params: _params)
        new(response)
      rescue ResourceNotFound
        nil
      end

      def destroy!(deal_id)
        _params = { deal_id: deal_id }
        response = delete_json(DEAL_PATH, params: _params)
        true
      end

      # Find recent updated deals.
      # {http://developers.hubspot.com/docs/methods/deals/get_deals_modified}
      # @param count [Integer] the amount of deals to return.
      # @param offset [Integer] pages back through recent contacts.
      def recent(opts = {})
        response = get_json(RECENT_UPDATED_PATH, params: opts)
        response['results'].map { |h| new(h) }
      end
    end

    def update!(params={})
      self.class.update! self.deal_id, params
    end

    # Archives the contact in hubspot
    # {https://developers.hubspot.com/docs/methods/contacts/delete_contact}
    # @return [TrueClass] true
    def destroy!
      self.class.destroy!(deal_id)
      @destroyed = true
    end

    def destroyed?
      !!@destroyed
    end
  end
end
