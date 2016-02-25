module RequestHelpers
  def response_json
    JSON.parse(response.body)
  end

  def auth_headers_for(user)
    {
      'HTTP_AUTHORIZATION' => "Token token=#{user.authentication_token}, email=#{user.email}"
    }
  end
end
