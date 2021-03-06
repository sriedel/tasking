require 'rspec/its'
require 'byebug'
require_relative '../lib/tasking'

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.syntax = :should
  end

  config.expect_with :rspec do |expect|
    expect.syntax = [ :should, :expect ]
  end

  config.order = :random
  Kernel.srand config.seed
end

RSpec::Expectations.configuration.on_potential_false_positives = :nothing
