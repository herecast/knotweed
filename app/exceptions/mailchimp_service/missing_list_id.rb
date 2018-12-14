module MailchimpService
  class MissingListId < ::StandardError
    attr_reader :listserv
    def initialize(listserv)
      @listserv = listserv
      super("Cannot complete operation. Listserv: #{listserv.name} has no Mailchimp list id")
    end
  end
end
