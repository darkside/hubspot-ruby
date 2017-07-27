module Hubspot
  class Utils
    class << self
      # Parses the hubspot properties format into a key-value hash
      def properties_to_hash(props)
        newprops = {}
        props.each{ |k,v| newprops[k] = v["value"] }
        newprops
      end

      # Turns a hash into the hubspot properties format
      def hash_to_properties(hash, opts = {})
        key_name = opts[:key_name] || "property"
        hash.map{ |k,v| { key_name => k.to_s, "value" => v}}
      end

      # Transform hash keys to underscore
      def underscore_hash(hash)
        hash.map { |k,v| [k.underscore, v] }.to_h
      end

      # Transform hash keys to camelcase
      def camelize_hash(hash)
        hash.map { |k,v| [k.camelize(:lower), v] }.to_h
      end

    end
  end
end
