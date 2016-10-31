# encoding: utf-8
require 'spec_helper'
require "logstash/filters/geocoding"

describe LogStash::Filters::Geocoding do
  describe "Set to Hello World" do
    let(:config) do <<-CONFIG
      filter {
        geocoding {
          message => "test message"
        }
      }
    CONFIG
    end

    sample("message" => "some text") do
      expect(subject.get("message")).to eq('test message')
    end
  end
end
