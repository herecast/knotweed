class Admin::OntotextController
  include HTTParty
  base_uri 'http://tech.ontotext.com'
  headers 'Content-Type'=>"application/vnd.ontotext.ces.document+xml;charset=UTF-8"
  # debug_output

  # override post method here to insert auth config
  def self.post(dest, options)
    options.merge!({ :basic_auth => 
                      { username: Figaro.env.ontotext_api_username,
                        password: Figaro.env.ontotext_api_password },
                     :timeout => 10*60 }) 
    super(dest, options)
  end

end
