require 'json'

class Annotation < ActiveRecord::Base

  belongs_to :annotation_report

  attr_accessible :accepted, :annotation_id, :annotation_report_id, :startnode, :endnode, :annotation_type,
                  :is_generated, :lookup_class, :token_feature, :recognized_class, :annotated_string,
                  :instance

  def status
    if accepted == true
      "accepted"
    elsif accepted == false
      "rejected"
    else
      "pending"
    end
  end

  def cached_http_get(url, params)
    Rails.cache.fetch([url, params], :expires => 1.hour) do
      response = HTTParty.get(url, params)
      {:code => response.code, :body => response.body}
    end
  end

  def edges

    edges = nil

    if lookup_class
      query = CGI::escape "
      PREFIX sbtxo:<http://www.subtext.org/ontology/>
      PREFIX sbtxr:<http://www.subtext.org/resource/>
      PREFIX sbtxd: <http://www.subtext.org/Document/>
      PREFIX rdfs:<http://www.w3.org/2000/01/rdf-schema#>
      PREFIX rdf:<http://www.w3.org/1999/02/22-rdf-syntax-ns#>
      PREFIX pub: <http://ontology.ontotext.com/publishing#>

      SELECT * 
      WHERE { 
        <#{lookup_class}>  ?predicate ?object .

        FILTER (
          ?predicate != <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> 
          )

      }"

      options = { :headers => { "Accept" => "application/sparql-results+json" } }

      response = self.cached_http_get(Figaro.env.SESAME_RDF_ENDPOINT + "/repositories/subtext?query=#{query}&queryLn=sparql", options)

      if response[:code] == 200
        response[:body]
        result = JSON.parse(response[:body])
        edges = result["results"]["bindings"]
      end

    end

    edges

  end

end
