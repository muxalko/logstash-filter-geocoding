Gem::Specification.new do |s|
  s.name = 'logstash-filter-geocoding'
  s.version = '0.1.1'
  s.licenses = ['Apache-2.0']
  s.summary = "This example filter replaces the contents of the message field with the specified value."
  s.description     = "This gem is a Logstash plugin required to be installed on top of the Logstash core pipeline using $LS_HOME/bin/logstash-plugin install gemname. This gem is not a stand-alone program"
  s.authors = ["Muxa"]
  s.email = 'muxa.baba@gmail.com'
  s.homepage = "http://www.elastic.co/guide/en/logstash/current/index.html"
  s.require_paths = ["lib"]

  # Files
  s.files = Dir['lib/**/*','spec/**/*','vendor/**/*','*.gemspec','*.md','CONTRIBUTORS','Gemfile','LICENSE','NOTICE.TXT']
   # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "filter" }

  # Gem dependencies
  s.add_runtime_dependency "logstash-core-plugin-api", "~> 2.0"
  s.add_runtime_dependency "rest-client", "= 2.0.0"
  s.add_development_dependency 'logstash-devutils', '~> 0'
end
