module MailchimpService
  class NoSubscribersPresent < ::StandardError
    attr_reader :digest
    def initialize(digest)
      @digest = digest
      super("Cannot continue, no subscribers are specified in ListservDigest: #{digest.inspect}")
    end
  end
end
