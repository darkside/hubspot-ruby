require 'hubspot/utils'
require 'httparty'

module Hubspot
  #
  # HubSpot Contact Properties API
  #
  # {http://developers.hubspot.com/docs/methods/contacts/get_properties}
  #
  class Property
    delegate :camelize_hash, :underscore_hash, :hash_to_properties, :connection, :get_json,
      :post_json, :put_json, :delete_json, to: :class

    # Class Methods
    class << self
      delegate :camelize_hash, :hash_to_properties, :underscore_hash, to: Utils
      delegate :connection, to: Hubspot
      delegate :get_json, :post_json, :put_json, :delete_json, to: :connection

      # Get all properties
      # {http://developers.hubspot.com/docs/methods/contacts/get_properties}
      # @return [Hubspot::PropertyCollection] the paginated collection of
      # properties
      def all(opts = {})
        response = get_json(collection_path, opts)
        response.map{|h| new(h) }
      end

      # Creates a new Property
      # {http://developers.hubspot.com/docs/methods/contacts/create_property}
      # @return [Hubspot::Property] the created property
      # @raise [Hubspot::DuplicateResource] if a property already exists with
      #   the given name
      # @raise [Hubspot::RequestError] if the creation fails
      def create!(name, params = {})
        # Merge the name with the rest of the params
        params_with_name = params.stringify_keys.merge("name" => name)
        # Merge in sensible defaults so we don't have to specify everything
        params_with_name.reverse_merge! default_creation_params
        # Transform keys to Hubspot's camelcase format
        params_with_name = camelize_hash(params_with_name)

        response = send(create_method, creation_path, body: params_with_name.to_json)
        new(response)
      end

      # Sometimes it's easier to delete things by name than instantiating them
      def destroy!(name)
        response = delete_json(deletion_path, params: { name: name})
        true
      end

      protected

      def create_method
        :post_json
      end

      def collection_path
        raise NotImplementedError
      end

      def instance_path
        raise NotImplementedError
      end

      def creation_path
        collection_path
      end

      def deletion_path
        instance_path
      end

      def default_creation_params
        {
          "description"   => "",
          "group_name"    => "contactinformation",
          "type"          => "string",
          "field_type"    => "text",
        }
      end
    end

    delegate :instance_path, to: :class

    attr_accessor :name, :description, :group_name, :type, :field_type,
      :form_field, :display_order, :options

    def initialize(hash)
      # Transform hubspot keys into ruby friendly names
      hash = underscore_hash(hash)
      # Assign anything we have an accessor for with the same name
      hash.each do |key, value|
        self.send(:"#{key}=", value) if self.respond_to?(:"#{key}=")
      end
    end

    # Archives the contact property in hubspot
    # {http://developers.hubspot.com/docs/methods/contacts/delete_property}
    # @return [TrueClass] true
    def destroy!
      @destroyed = self.class.destroy! self.name
    end

    def destroyed?
      !!@destroyed
    end

  end
end
