module AuthenticationHelpers
  def api_authenticate(user,options={success:true})
    if options[:success]
      request.env['HTTP_AUTHORIZATION'] = \
        "Token token=#{user.authentication_token}, \
        email=#{user.email}"
    else
      request.env['HTTP_AUTHORIZATION'] = '' 
    end
  end
end
