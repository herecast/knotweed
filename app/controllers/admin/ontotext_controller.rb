class Admin::OntotextController
  include HTTParty
  base_uri Figaro.env.ontotext_api_base_uri
  
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
    request_headers = { 'Content-type' => "application/vnd.ontotext.ces.document+xml;charset=UTF-8" }
    if options.has_key? :headers and options[:headers].present?
      options[:headers].merge! request_headers
    else
      options[:headers] = request_headers
    end
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

  def self.get_annotations(content_id, options={})
    query = CGI::escape "PREFIX sbtxd: <http://www.subtext.org/Document/>
    PREFIX pub: <http://ontology.ontotext.com/publishing#>


    select * 
    where { sbtxd:#{content_id}  pub:title ?title ;
    pub:content ?content ;
    pub:annotatedContent ?annotation .
    }"

    request_headers = { "Accept" => "application/sparql-results+json" }
    if options.has_key? :headers and options[:headers].present?
      options[:headers].merge! request_headers
    else
      options[:headers] = request_headers
    end

    response = self.get(Figaro.env.sesame_rdf_endpoint + "?query=#{query}&queryLn=sparql", options)
    if response.code == 200
      response.body
    else
      false
    end
  end

end
