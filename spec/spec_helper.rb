# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

RSpec.configure do |config|
  config.tty = true
end # configure

require File.expand_path("../dummy/config/environment.rb",  __FILE__)
require "rails/test_help"

Rails.backtrace_cleaner.remove_silencers!

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }
