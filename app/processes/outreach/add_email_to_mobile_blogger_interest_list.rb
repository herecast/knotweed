module Outreach
  class AddEmailToMobileBloggerInterestList
    include MailchimpAPI

    def self.call(email)
      self.new.call(email)
    end

    def call(email)
      subscribe_email_to_mobile_blogger_interest_list(email)
    end
  end
end