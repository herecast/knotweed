# frozen_string_literal: true

module AuthenticationHelpers
  def api_authenticate(args = {})
    args = { user: nil, success: true }.merge(args)
    user = args[:user]
    if args[:success]
      if user
        @request.headers['HTTP_AUTHORIZATION'] = \
          "Token token=#{user.authentication_token}, \
          email=#{user.email}"
      end
    else
      @request.headers['HTTP_AUTHORIZATION'] = ''
    end
  end
end
