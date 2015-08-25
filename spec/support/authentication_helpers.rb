module AuthenticationHelpers
  def api_authenticate(args={})
    args = {user: nil, success: true}.merge(args)
    user = args[:user]
    if args[:success]
      request.env['HTTP_AUTHORIZATION'] = \
        "Token token=#{user.authentication_token}, \
        email=#{user.email}"
    else
      request.env['HTTP_AUTHORIZATION'] = '' 
    end
  end
end
