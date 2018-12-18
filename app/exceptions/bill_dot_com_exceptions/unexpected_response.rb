# frozen_string_literal: true

module BillDotComExceptions
  class UnexpectedResponse < ::StandardError
    attr_reader :response

    def initialize(response)
      @response = response
      super("An unexpected response was returned by the Bill.com API: #{response}")
    end
  end
end
