def stub_retrieve_update_fields_from_repo(content, repo)
  test_cat = "test_category"
  stub_request(:post, repo.sesame_endpoint).
    with(:body => {"query"=>"\n      prefix pub: <http://ontology.ontotext.com/publishing#>\n      PREFIX sbtxd: <http://www.subtext.org/Document/>\n\n      select ?category\n      where {\n        OPTIONAL { sbtxd:#{content.id} pub:hasCategory ?category . }\n      }"}).
      to_return(status: 200, body: "<?xml version='1.0' encoding='UTF-8'?>
    <sparql xmlns='http://www.w3.org/2005/sparql-results#'>
      <head>
        <variable name='category'/>
      </head>
      <results>
        <result>
          <binding name='category'>
            <uri>http://data.ontotext.com/watt/Category/#{test_cat}</uri>
          </binding>
        </result>
      </results>
    </sparql>", 
    headers: {"Content-Type" => "application/sparql-results+xml;charset=UTF-8"})
  test_cat
end
