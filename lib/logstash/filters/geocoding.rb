# encoding: utf-8
require 'logstash/filters/base'
require 'logstash/namespace'
require "logstash/json"
require 'rest-client'
require 'jsonpath'
require "addressable/uri"

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

  # Define the field to look for response data. If this setting is
  # omitted, the JSON at the root (top level) of the event will be considered..
  #
  # For example, if you want the data to look for the data in the `data` field:
  # [source,ruby]
  #     filter {
  #       geocoding {
  #         lookfor => "data"
  #       }
  #     }
  #
  # JSON in the `lookfor` field will be expanded into a
  # data structure in the `target` field below.
  #
  config :lookfor, :validate => :string

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
  # JSON of the `lookfor` field will be expanded into a
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
  config :url, :validate => :string, :required => true

  # Append values to the `tags` field when there has been no
  # successful match
  config :tag_on_failure, :validate => :array, :default => ["_jsonparsefailure"]

  # Allow to skip filter on invalid response (allows to handle data without warnings)
  config :skip_on_invalid_response, :validate => :boolean, :default => false

  public
  def register
    # Nothing to do here
  end

  # def register

  public
  def filter(event)
    @logger.debug? && @logger.debug("Running geolocation filter", :event => event.get(@source))

    if @target && @url
      begin
        case @method
          when "post"
            source = event.get(@source)
            return unless source
            _url = Addressable::URI.parse(@url).normalize.to_s
            @logger.debug? && @logger.debug("HTTP Request ", :url => _url, :json => source)
            response = RestClient.post(_url, source.to_json, {content_type: :json, accept: :json})
          else
            source = event.get(@source)
            return unless source
            _url = Addressable::URI.parse(@url+source).normalize.to_s
            @logger.debug? && @logger.debug("HTTP Request ", :url => _url)
            response =RestClient.get(_url, {accept: :json})
        end

      rescue => e
        @logger.debug? && @logger.debug("Error at http request", :exception => e)
        event.set["[#{@target}][status]"] = e.class.name.to_s
        event.set["[#{@target}][message]"] = e.to_s
        return
      end

      @logger.debug? && @logger.debug("HTTP response", :response => response)
      parsedTarget = LogStash::Json.load(response.body)
      if parsedTarget["status"] == 'SUCCESS'
        if @lookfor
          event.set(@target, JsonPath.new('$..'+@lookfor).first(parsedTarget))
        else
          event.set(@target, parsedTarget)
        end
      else
        event.set(@target, parsedTarget)
      end

      unless parsedTarget.is_a?(Hash)
        @tag_on_failure.each { |tag| event.tag(tag) }
        @logger.warn("Parsed JSON object/hash requires a target configuration option", :source => @source, :raw => source)
        return
      end

      @logger.debug? && @logger.debug("Message is now:", :event => event.get(@target) )

      # filter_matched should go in the last line of our successful code
      filter_matched(event)

    end # if #target
  end # def filter
end # class LogStash::Filters::Geocoding
