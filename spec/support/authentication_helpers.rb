module AuthenticationHelpers
  def api_authenticate(args={})
    args = {user: nil, success: true}.merge(args)
    user = args[:user]
    if args[:success]
      if user
        request.env['HTTP_AUTHORIZATION'] = \
          "Token token=#{user.authentication_token}, \
          email=#{user.email}"
      end
      if args[:consumer_app]
        request.env['Consumer-App-Uri'] = args[:consumer_app].uri
      end
    else
      request.env['HTTP_AUTHORIZATION'] = '' 
    end
  end
end
