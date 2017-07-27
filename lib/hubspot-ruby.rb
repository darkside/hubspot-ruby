require 'active_support'
require 'active_support/core_ext'
require 'httparty'
require 'hubspot/exceptions'
require 'hubspot/config'
require 'hubspot/connection'
require 'hubspot/property'
require 'hubspot/contact'
require 'hubspot/contact_property'
require 'hubspot/form'
require 'hubspot/blog'
require 'hubspot/topic'
require 'hubspot/deal'
require 'hubspot/deal_property'

module Hubspot
  def self.configure(config={})
    Hubspot::Config.configure(config)
  end

  def self.connection
    @connection ||= Connection.new
  end
end
