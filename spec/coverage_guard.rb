#This file is intended to warn us when code coverage falls below a set percentage
#the file intentinally does not end with _spec, so the tests in this file must be called
#directly on the command line to get the spec to run.
#

require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'

describe 'Code Coverage' do
  let(:minimum_coverage) { 84.0 }
  let(:result) do
    if ENV["CIRCLE_ARTIFACTS"]
      JSON.parse File.read(ENV["CIRCLE_ARTIFACTS"] + '/coverage/.last_run.json')
    else
      JSON.parse File.read(Rails.root.join('coverage', '.last_run.json'))
    end
  end

  it 'should pass our minimum percentage' do
    expect(result['result']['covered_percent']).to be >= minimum_coverage
  end
end
