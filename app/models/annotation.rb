# == Schema Information
#
# Table name: annotations
#
#  id                   :integer          not null, primary key
#  annotation_report_id :integer
#  annotation_id        :string(255)
#  accepted             :boolean
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  startnode            :string(255)
#  endnode              :string(255)
#  annotation_type      :string(255)
#  is_generated         :boolean
#  lookup_class         :string(255)
#  token_feature        :string(255)
#  recognized_class     :string(255)
#  annotated_string     :string(255)
#  instance             :string(255)
#  edges                :text
#  is_trusted           :boolean
#  rule                 :string(255)
#

require 'json'

class Annotation < ActiveRecord::Base

  serialize :edges, Array

  belongs_to :annotation_report

  attr_accessible :accepted, :annotation_id, :annotation_report_id, :startnode, :endnode, :annotation_type,
                  :is_generated, :lookup_class, :token_feature, :recognized_class, :annotated_string,
                  :instance, :edges, :is_trusted, :rule

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

  def set_edges
    unless self.edges.present?
      self.edges = self.find_edges
    end
  end

  def find_edges

    found_edges = nil

    if is_trusted
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

      # NOTE: can't cache this because we're iterating quickly with these reports
      response = HTTParty.get(annotation_report.repository.sesame_endpoint + "?query=#{query}&queryLn=sparql", options)

      if response.code == 200
        result = JSON.parse(response.body)
        found_edges = result["results"]["bindings"]
      end
    end

    found_edges

  end

  def lookup_label
    if edges
      label = nil
      edges.each do |e|
        if e["predicate"]["value"] == "http://www.w3.org/2000/01/rdf-schema#label"
          label = e["object"]["value"]
        end
      end
      label
    else
      "Lookup"
    end
  end

  def self.parse_uri_for_class(uri)
    uri.split("/")[-1].split("#")[-1]
  end

  def parsed_lookup_class
    lookup_class.present? ? Annotation.parse_uri_for_class(lookup_class) : "Lookup"
  end
    

  def closest_edges_labels
    closest = []
    if edges.present?
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
