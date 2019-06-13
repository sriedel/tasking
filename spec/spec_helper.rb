require 'rspec/its'
require_relative '../lib/tasker'

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.syntax = :should
  end

  config.order = :random
  Kernel.srand config.seed
end

RSpec::Expectations.configuration.on_potential_false_positives = :nothing
