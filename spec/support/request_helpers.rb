module RequestHelpers
  def auth_headers_for(user)
    {
      'HTTP_AUTHORIZATION' => "Token token=#{user.authentication_token}, email=#{user.email}"
    }
  end

  def response_json
    transform_to_symbolized_keys JSON.parse(response.body)
  end

  def symbolize_recursive(hash)
    {}.tap do |h|
      hash.each {|key, value| h[key.to_sym] = transform_to_symbolized_keys(value) }
    end
  end

  def transform_to_symbolized_keys(thing)
    case thing
    when Hash; symbolize_recursive(thing)
    when Array; thing.map{|v| transform_to_symbolized_keys(v)}
    else; thing
    end
  end
end
