# encoding: utf-8
require 'logstash/filters/base'
require 'logstash/namespace'
require "logstash/json"
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
  #   geocoding {
  #   }
  # }
  #
  config_name "geocoding"

  # The configuration for the Geocoding filter:
  # [source,ruby]
  #     source => source_field
  #
  # For example, if you have JSON data in the `cellData` field:
  # [source,ruby]
  #     filter {
  #       json {
  #         source => "cellData"
  #       }
  #     }
  #
  # The above would parse the json from the `message` field
  config :source, :validate => :string, :required => true


  # Define the target field for placing the parsed data. If this setting is
  # omitted, the JSON data will be stored at the root (top level) of the event.
  #
  # For example, if you want the data to be put in the `geoData` field:
  # [source,ruby]
  #     filter {
  #       geocoding {
  #         target => "geoData"
  #       }
  #     }
  #
  # JSON in the value of the `source` field will be expanded into a
  # data structure in the `target` field.
  #
  # NOTE: if the `target` field already exists, it will be overwritten!
  config :target, :validate => :string

  # Define the request method. If this setting is omitted, "get" will be used.
  # Only "get" and "post" are implemented
  # For example, if you want the request method to be post:
  # [source,ruby]
  #     filter {
  #       geocoding {
  #         method => "post"
  #       }
  #     }
  #
  # NOTE: if the `method` field already exists, it will be overwritten!
  config :method, :validate => :string, :default => "get"

  # The configuration for the Geocoding filter:
  # [source,ruby]
  #     url => api_url_string
  #
  # For example, if you have JSON data in the `cellData` field:
  # [source,ruby]
  #     filter {
  #       json {
  #         url => "https://www.googleapis.com/geolocation/v1/geolocate?key=1234567"
  #       }
  #     }
  #
  # The above would parse the json from the `message` field
  config :url, :validate => :string, :required => true

  # Append values to the `tags` field when there has been no
  # successful match
  config :tag_on_failure, :validate => :array, :default => ["_jsonparsefailure"]

  # Allow to skip filter on invalid json (allows to handle json and non-json data without warnings)
  config :skip_on_invalid_json_response, :validate => :boolean, :default => false

  public
  def register
    # Nothing to do here
  end # def register

  public
  def filter(event)
    @logger.debug? && @logger.debug("Running geolocation filter", :event => event)

    source = event.get(@source)
    return unless source

    # begin
    #   parsedSource = LogStash::Json.load(source)
    # rescue => e
    #   unless @skip_on_invalid_json
    #     @tag_on_failure.each{|tag| event.tag(tag)}
    #     @logger.warn("Error parsing json", :source => @source, :raw => source, :exception => e)
    #   end
    #   return
    # end

    if @target && @url
      begin
        case @method
          when "post"
            response = RestClient.post(@url,source.to_json,{content_type: :json, accept: :json})
          else
            response =RestClient.get(@url,{accept: :json})
        end

      rescue => e
        @logger.warn("Error at http request", :exception => e)
        @logger.debug? && @logger.debug("Response : #{response}")
        parsedTarget = LogStash::Json.load(e.response)
        event.set(@target,parsedTarget)
        return
      end
      parsedTarget = LogStash::Json.load(response.body)

      #fix key name for geo_point (location.lng => location.lon)
      parsedTarget["location"]["lon"] = parsedTarget["location"]["lng"]
      parsedTarget["location"].delete("lng")

      event.set(@target,parsedTarget)
      # parsedTarget.each{|k, v| event.set(@target.k, v)}

    else
      unless parsedTarget.is_a?(Hash)
        @tag_on_failure.each{|tag| event.tag(tag)}
        @logger.warn("Parsed JSON object/hash requires a target configuration option", :source => @source, :raw => source)
        return
      end

    @logger.debug? && @logger.debug("Message is now: #{event.get(@target)}")

    # filter_matched should go in the last line of our successful code
    filter_matched(event)
    end # if #target
  end # def filter
end # class LogStash::Filters::Geocoding
