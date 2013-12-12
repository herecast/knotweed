class Admin::OntotextController
  include HTTParty
  base_uri 'http://tech.ontotext.com'
  headers 'Content-Type'=>"application/vnd.ontotext.ces.document+xml;charset=UTF-8"
  # debug_output

end
