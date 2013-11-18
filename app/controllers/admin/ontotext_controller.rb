class Admin::OntotextController
  include HTTParty
  base_uri 'http://tech.ontotext.com'
  headers 'Content-Type'=>"application/vnd.ontotext.ces.document+xml"
  debug_output

end
