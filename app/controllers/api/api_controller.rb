class Api::ApiController < ActionController::Base

  # already handled by nginx
  #http_basic_authenticate_with name: Figaro.env.api_username, password: Figaro.env.api_password

end
