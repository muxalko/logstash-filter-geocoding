# encoding: utf-8
require 'logstash/filters/base'
require 'logstash/namespace'
require 'rest-client'

# This example filter will replace the contents of the default
# message field with whatever you specify in the configuration.
#
# It is only intended to be used as an example.
class LogStash::Filters::Geocoding < LogStash::Filters::Base

  # Setting the config_name here is required. This is how you
  # configure this filter from your Logstash config.
  #
  # filter {
  #   example {
  #     message => "My message..."
  #   }
  # }
  #
  config_name "geocoding"

  # Replace the message with this value.
  config :message, :validate => :string, :default => "test 123"


  public
  def register
    # Add instance variables
  end # def register

  public
  def filter(event)

    if @message

      response = RestClient.post("https://www.googleapis.com/geolocation/v1/geolocate?key=AIzaSyAnWuLpHCsyykK0Z6Is1sZeYHGr8HcZrMs",
          { 'cellTowers' => [
              {
                  'cellId' => 32446,
                  'locationAreaCode' => 56964,
                  'mobileCountryCode' => 310,
                  'mobileNetworkCode' => 410
              }
          ]}.to_json, {content_type: :json, accept: :json})

      @logger.debug? && @logger.debug("Response : #{response}")
      # using the event.set API
      parsed = JSON.parse(response.body)
      parsed.each{|k, v| event.set(k, v)}

      # if locObj.location
      #   # event.set(lat,parsed.location.lat)
      #   # event.set(lng,parsed.location.lng)
      #   # event.set(accuracy,locObj.accuracy)
      # end

      # if locObj.error
      #   event.set(error,locObj.error.message)
      # end



      # Replace the event message with our message as configured in the
      # config file.
      event.set(message, @message)
      # correct debugging log statement for reference
      # using the event.get API
      @logger.debug? && @logger.debug("Message is now: #{event.get("message")}")
    end

    # filter_matched should go in the last line of our successful code
    filter_matched(event)
  end # def filter
end # class LogStash::Filters::Example
