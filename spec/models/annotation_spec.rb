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

require 'spec_helper'

describe Annotation do
  describe "status" do
    it "should return 'accepted' when accepted is true" do
      ann = FactoryGirl.create(:annotation, accepted: true)
      ann.status.should== "accepted"
    end
    it "should return 'pending' when accepted is null" do
      ann = FactoryGirl.create(:annotation, accepted: nil)
      ann.status.should== "pending"
    end
    it "should return 'rejected' when accepted is false" do
      ann = FactoryGirl.create(:annotation, accepted: false)
      ann.status.should== "rejected"
    end
  end

  describe "edges" do
    before do
      stub_request(:get, "#{ENV['SESAME_RDF_ENDPOINT']}?query=%0A%20%20%20%20%20%20PREFIX%20sbtxo:%3Chttp://www.subtext.org/ontology/%3E%0A%20%20%20%20%20%20PREFIX%20sbtxr:%3Chttp://www.subtext.org/resource/%3E%0A%20%20%20%20%20%20PREFIX%20sbtxd:%20%3Chttp://www.subtext.org/Document/%3E%0A%20%20%20%20%20%20PREFIX%20rdfs:%3Chttp://www.w3.org/2000/01/rdf-schema%23%3E%0A%20%20%20%20%20%20PREFIX%20rdf:%3Chttp://www.w3.org/1999/02/22-rdf-syntax-ns%23%3E%0A%20%20%20%20%20%20PREFIX%20pub:%20%3Chttp://ontology.ontotext.com/publishing%23%3E%0A%0A%20%20%20%20%20%20SELECT%20*%20%0A%20%20%20%20%20%20WHERE%20%7B%20%0A%20%20%20%20%20%20%20%20%3Chttp://www.subtext.org/resource/Company_T.12345%3E%20%20?predicate%20?object%20.%0A%20%20%20%20%20%20%20%20OPTIONAL%20%7B%20?object%20%3Chttp://www.w3.org/2000/01/rdf-schema%23label%3E%20?label%20%7D%0A%0A%20%20%20%20%20%20%20%20FILTER%20(%0A%20%20%20%20%20%20%20%20%20%20?predicate%20!=%20%3Chttp://www.w3.org/1999/02/22-rdf-syntax-ns%23type%3E%20%0A%20%20%20%20%20%20%20%20%20%20)%0A%0A%20%20%20%20%20%20%7D&queryLn=sparql").
      with(:headers => {'Accept'=>'application/sparql-results+json'}).
      to_return(:body => File.new('spec/fixtures/annotation_instance_not_found.json', 'r'), :status => 200)

    stub_request(:get, "#{ENV['SESAME_RDF_ENDPOINT']}?query=%0A%20%20%20%20%20%20PREFIX%20sbtxo:%3Chttp://www.subtext.org/ontology/%3E%0A%20%20%20%20%20%20PREFIX%20sbtxr:%3Chttp://www.subtext.org/resource/%3E%0A%20%20%20%20%20%20PREFIX%20sbtxd:%20%3Chttp://www.subtext.org/Document/%3E%0A%20%20%20%20%20%20PREFIX%20rdfs:%3Chttp://www.w3.org/2000/01/rdf-schema%23%3E%0A%20%20%20%20%20%20PREFIX%20rdf:%3Chttp://www.w3.org/1999/02/22-rdf-syntax-ns%23%3E%0A%20%20%20%20%20%20PREFIX%20pub:%20%3Chttp://ontology.ontotext.com/publishing%23%3E%0A%0A%20%20%20%20%20%20SELECT%20*%20%0A%20%20%20%20%20%20WHERE%20%7B%20%0A%20%20%20%20%20%20%20%20%3Chttp://www.subtext.org/resource/Company_T.7687%3E%20%20?predicate%20?object%20.%0A%20%20%20%20%20%20%20%20OPTIONAL%20%7B%20?object%20%3Chttp://www.w3.org/2000/01/rdf-schema%23label%3E%20?label%20%7D%0A%0A%20%20%20%20%20%20%20%20FILTER%20(%0A%20%20%20%20%20%20%20%20%20%20?predicate%20!=%20%3Chttp://www.w3.org/1999/02/22-rdf-syntax-ns%23type%3E%20%0A%20%20%20%20%20%20%20%20%20%20)%0A%0A%20%20%20%20%20%20%7D&queryLn=sparql").
         with(:headers => {'Accept'=>'application/sparql-results+json'}).
         to_return(:status => 200, :body => File.new('spec/fixtures/annotation_instance_found.json', 'r'))
    end

    it "should return empty array when it has no lookup_class" do
      ann = FactoryGirl.create(:annotation, lookup_class: nil)
      ann.edges.should== []
    end
    it "should return an empty list when instance is not found" do
      ann = FactoryGirl.create(:lookup_annotation, instance: "http://www.subtext.org/resource/Company_T.12345")
      ann.set_edges
      ann.edges.should== []
    end
    it "should return an non-empty list when instance is found" do
      ann = FactoryGirl.create(:lookup_annotation, instance: "http://www.subtext.org/resource/Company_T.7687")
      ann.set_edges
      ann.edges.length.should be >= 1
    end
  end

  describe "#lookup_label" do
    before do
      @annotation = FactoryGirl.create :annotation
    end

    let(:edge) { { "predicate" => { "value" => "http://www.w3.org/2000/01/rdf-schema#label" }, "object" => { "value" => "New Label" } } }

    context "when edge present" do
      it "returns label containing object value" do
        @annotation.edges << edge
        expect(@annotation.lookup_label).to eq 'New Label'
      end
    end

    context 'when no edges' do
      it "returns generic label" do
        expect(@annotation.lookup_label).to eq 'Lookup'
      end
    end
  end

  describe '#parsed_lookup_class' do
    before do
      @annotation = FactoryGirl.create :annotation
    end

    context "when lookup_class present" do
      it "returns parsed uri" do
        @annotation.update_attribute(:lookup_class, 'http://www.subtext.org/ontology/Company')
        parsed_uri = Annotation.parse_uri_for_class(@annotation.lookup_class)
        expect(parsed_uri).to eq 'Company'
      end
    end

    context "when lookup_class not present" do
      it "returns generic response" do
        expect(@annotation.parsed_lookup_class).to eq "Lookup"
      end
    end
  end

  describe '#closest_edges_label' do
    before do
      @annotation = FactoryGirl.create :annotation
    end

    let(:edge) { { "predicate" => { "value" => "http://www.subtext.org/ontology/Company" }, "object" => { "value" => "New Label" } } }
    let(:labeled_edge) { { "predicate" => { "value" => "http://www.subtext.org/ontology/Company" }, "object" => { "value" => "New Label" }, "label" => { "value" => "New Label Value" } } } 

    context "when edges present without label" do
      it "returns closest edges" do
        @annotation.edges << edge
        expect(@annotation.closest_edges_labels.first).to include 'Company', 'New Label'
      end
    end

    context "when edges present with label" do
      it "returns closest edges" do
        @annotation.edges << labeled_edge
        expect(@annotation.closest_edges_labels.first).to include 'Company', 'New Label Value'
      end
    end

    context "when no edges" do
      it "returns false" do
        expect(@annotation.closest_edges_labels).to be false
      end
    end
  end
      
end
