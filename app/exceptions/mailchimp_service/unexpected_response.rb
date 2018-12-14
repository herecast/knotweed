# frozen_string_literal: true

module MailchimpService
  class UnexpectedResponse < ::StandardError
    attr_reader :response

    def initialize(response)
      @response = response

      super("An unexpected response was returned by the Mailchimp API:  #{response.body}")
    end
  end
end
