class Admin::OntotextController
  include HTTParty
  base_uri 'http://tech.ontotext.com'
  headers 'Content-Type'=>"application/vnd.ontotext.ces.document+xml;charset=UTF-8"
  
  # set debug_output based on environment
  def self.set_debug_output
    unless Rails.env.production?
      debug_output
    end
  end
  set_debug_output

  # override post method here to insert auth config
  def self.post(dest, options)
    options.merge!({ :basic_auth => 
                      { username: Figaro.env.ontotext_api_username,
                        password: Figaro.env.ontotext_api_password },
                     :timeout => 10*60 }) 
    super(dest, options)
  end

  # ping the rdf to gate endpoint and return the GATE xml
  def self.rdf_to_gate(content_id, options={})
    response = self.get(Figaro.env.rdf_to_gate_endpoint + "/rdfToGate/#{content_id.to_s}", options)
    if response.code == 200
      response.body
    else
      false
    end
  end

end
