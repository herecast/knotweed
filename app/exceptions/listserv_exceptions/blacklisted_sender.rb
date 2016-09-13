module ListservExceptions
  class BlacklistedSender < ::StandardError
    attr_reader :email, :listserv
    def initialize(listserv, email)
      @listserv = listserv
      @mail = email
      super("#{listserv.name} has blacklisted sender: #{email}")
    end
  end
end
