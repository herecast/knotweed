require 'json'

class Annotation < ActiveRecord::Base

  serialize :edges, Array

  belongs_to :annotation_report

  attr_accessible :accepted, :annotation_id, :annotation_report_id, :startnode, :endnode, :annotation_type,
                  :is_generated, :lookup_class, :token_feature, :recognized_class, :annotated_string,
                  :instance, :edges

  before_save :set_edges

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

  def set_edges
    unless self.edges.present?
      self.edges = self.find_edges
    end
  end

  def find_edges

    found_edges = nil

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
        <#{instance}>  ?predicate ?object .
        OPTIONAL { ?object <http://www.w3.org/2000/01/rdf-schema#label> ?label }

        FILTER (
          ?predicate != <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> 
          )

      }"

      options = { :headers => { "Accept" => "application/sparql-results+json" } }

      response = self.cached_http_get(Figaro.env.SESAME_RDF_ENDPOINT + "/repositories/subtext?query=#{query}&queryLn=sparql", options)

      if response[:code] == 200
        response[:body]
        result = JSON.parse(response[:body])
        found_edges = result["results"]["bindings"]
      end

    end

    found_edges

  end

  def lookup_label
    if lookup_class
      label = nil
      edges.each do |e|
        if e["predicate"]["value"] == "http://www.w3.org/2000/01/rdf-schema#label"
          label = e["object"]["value"]
        end
      end
      label
    else
      false
    end
  end

  def self.parse_uri_for_class(uri)
    uri.split("/")[-1].split("#")[-1]
  end

  def parsed_lookup_class
    lookup_class.present? ? Annotation.parse_uri_for_class(lookup_class) : nil
  end
    

  def closest_edges_labels
    closest = []
    if lookup_class
      edges.each do |e|
        # skip label
        unless e["predicate"]["value"] == "http://www.w3.org/2000/01/rdf-schema#label"
          if e["label"]
            object_label = e["label"]["value"]
          else
            object_label = e["object"]["value"]
          end
          predicate = Annotation.parse_uri_for_class(e["predicate"]["value"])
          closest << [predicate, object_label]
        end
      end
      closest
    else
      false
    end
  end

end
