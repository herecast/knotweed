# == Schema Information
#
# Table name: annotation_reports
#
#  id            :integer          not null, primary key
#  content_id    :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  name          :string(255)
#  description   :text
#  json_response :text
#  repository_id :integer
#

require 'spec_helper'

describe AnnotationReport, :type => :model do
  describe "metrics" do
    before (:all) do 
      VCR.turn_on!
      VCR.insert_cassette('annotation_report')
    end

    after (:all) do
      VCR.eject_cassette('annotation_report')
      VCR.turn_off!
    end

    before do
      @repo = FactoryGirl.create(:repository)
      # stub requests
      stub_request(:get, "#{@repo.sesame_endpoint}?query=%0A%20%20%20%20%20%20PREFIX%20sbtxo:%3Chttp://www.subtext.org/ontology/%3E%0A%20%20%20%20%20%20PREFIX%20sbtxr:%3Chttp://www.subtext.org/resource/%3E%0A%20%20%20%20%20%20PREFIX%20sbtxd:%20%3Chttp://www.subtext.org/Document/%3E%0A%20%20%20%20%20%20PREFIX%20rdfs:%3Chttp://www.w3.org/2000/01/rdf-schema%23%3E%0A%20%20%20%20%20%20PREFIX%20rdf:%3Chttp://www.w3.org/1999/02/22-rdf-syntax-ns%23%3E%0A%20%20%20%20%20%20PREFIX%20pub:%20%3Chttp://ontology.ontotext.com/publishing%23%3E%0A%0A%20%20%20%20%20%20SELECT%20*%20%0A%20%20%20%20%20%20WHERE%20%7B%20%0A%20%20%20%20%20%20%20%20%3Chttp://www.subtext.org/resource/Company_T.7687%3E%20%20?predicate%20?object%20.%0A%20%20%20%20%20%20%20%20OPTIONAL%20%7B%20?object%20%3Chttp://www.w3.org/2000/01/rdf-schema%23label%3E%20?label%20%7D%0A%0A%20%20%20%20%20%20%20%20FILTER%20(%0A%20%20%20%20%20%20%20%20%20%20?predicate%20!=%20%3Chttp://www.w3.org/1999/02/22-rdf-syntax-ns%23type%3E%20%0A%20%20%20%20%20%20%20%20%20%20)%0A%0A%20%20%20%20%20%20%7D&queryLn=sparql").
      with(:headers => {'Accept'=>'application/sparql-results+json'}).
      to_return(:status => 200, :body => File.new('spec/fixtures/annotation_instance_found.json', 'r'))
    end

    it "should return recognized == 0 when there are no annotations" do
      ar = FactoryGirl.create(:annotation_report)
      expect(ar.metrics[:recognized]).to eq(0)
    end
    it "should return distinct_recognized == 0 when there are no annotations" do
      ar = FactoryGirl.create(:annotation_report)
      expect(ar.metrics[:distinct_recognized]).to eq(0)
    end
    it "should return correct_recognized == 0 when there are no annotations" do
      ar = FactoryGirl.create(:annotation_report)
      expect(ar.metrics[:correct_recognized]).to eq(0)
    end
    it "should return distinct_correct_recognized == 0 when there are no annotations" do
      ar = FactoryGirl.create(:annotation_report)
      expect(ar.metrics[:distinct_correct_recognized]).to eq(0)
    end
    it "should return trusted == 0 when there are no annotations" do
      ar = FactoryGirl.create(:annotation_report)
      expect(ar.metrics[:trusted]).to eq(0)
    end
    it "should return distinct_trusted == 0 when there are no annotations" do
      ar = FactoryGirl.create(:annotation_report)
      expect(ar.metrics[:distinct_trusted]).to eq(0)
    end
    it "should return correct_trusted == 0 when there are no annotations" do
      ar = FactoryGirl.create(:annotation_report)
      expect(ar.metrics[:correct_trusted]).to eq(0)
    end
    it "should return distinct_correct_trusted == 0 when there are no annotations" do
      ar = FactoryGirl.create(:annotation_report)
      expect(ar.metrics[:distinct_correct_trusted]).to eq(0)
    end
    it "should return recognized == 1 when there is 1 recognized annotation" do
      ar = FactoryGirl.create(:annotation_report)
      FactoryGirl.create(:annotation, annotation_report: ar, recognized_class: "SomeNonemptyValue")
      expect(ar.metrics[:recognized]).to eq(1)
    end
    it "should return recognized == 2 when there are 2 recognized annotations" do
      ar = FactoryGirl.create(:annotation_report)
      FactoryGirl.create(:annotation, annotation_report: ar, recognized_class: "SomeNonemptyValue")
      FactoryGirl.create(:annotation, annotation_report: ar, recognized_class: "SomeOtherNonemptyValue")
      expect(ar.metrics[:recognized]).to eq(2)
    end
    it "should return recognized == 0 when there is 1 trusted annotation" do
      ar = FactoryGirl.create(:annotation_report)
      FactoryGirl.create(
        :lookup_annotation,
        annotation_report: ar,
        recognized_class: "SomeNonemptyValue"
      )
      expect(ar.metrics[:recognized]).to eq(0)
    end
    it "should return distinct_recognized == 1 when there are 2 indistinct recognized annotations" do
      ar = FactoryGirl.create(:annotation_report)
      FactoryGirl.create(:annotation, annotation_report: ar, recognized_class: "SomeNonemptyValue", annotated_string: "SomeText")
      FactoryGirl.create(:annotation, annotation_report: ar, recognized_class: "SomeOtherNonemptyValue", annotated_string: "SomeText")
      expect(ar.metrics[:distinct_recognized]).to eq(1)
    end
    it "should return distinct_recognized == 2 when there are 2 distinct recognized annotations" do
      ar = FactoryGirl.create(:annotation_report)
      FactoryGirl.create(:annotation, annotation_report: ar, recognized_class: "SomeNonemptyValue", annotated_string: "SomeText")
      FactoryGirl.create(:annotation, annotation_report: ar, recognized_class: "SomeOtherNonemptyValue", annotated_string: "SomeNewText")
      expect(ar.metrics[:distinct_recognized]).to eq(2)
    end
    it "should return correct_recognized == 0 when there is 1 incorrect recognized annotation" do
      ar = FactoryGirl.create(:annotation_report)
      FactoryGirl.create(:annotation, annotation_report: ar, recognized_class: "SomeNonemptyValue", accepted: false )
      expect(ar.metrics[:correct_recognized]).to eq(0)
    end
    it "should return correct_recognized == 1 when there is 1 correct recognized annotation" do
      ar = FactoryGirl.create(:annotation_report)
      FactoryGirl.create(:annotation, annotation_report: ar, recognized_class: "SomeNonemptyValue", accepted: true )
      expect(ar.metrics[:correct_recognized]).to eq(1)
    end
    it "should return correct_recognized == 2 when there is 2 correct recognized annotations" do
      ar = FactoryGirl.create(:annotation_report)
      FactoryGirl.create(:annotation, annotation_report: ar, recognized_class: "SomeNonemptyValue", accepted: true )
      FactoryGirl.create(:annotation, annotation_report: ar, recognized_class: "SomeNonemptyValue", accepted: true )
      expect(ar.metrics[:correct_recognized]).to eq(2)
    end
    it "should return distinct_correct_recognized == 1 when there is 2 indistinct correct recognized annotations" do
      ar = FactoryGirl.create(:annotation_report)
      FactoryGirl.create(
        :annotation, annotation_report: ar, recognized_class: "SomeNonemptyValue", accepted: true, annotated_string: "SomeText"
      )
      FactoryGirl.create(
        :annotation, annotation_report: ar, recognized_class: "SomeNonemptyValue", accepted: true, annotated_string: "SomeText"
      )
      expect(ar.metrics[:distinct_correct_recognized]).to eq(1)
    end
    it "should return trusted == 1 when there is 1 trusted annotation" do
      ar = FactoryGirl.create(:annotation_report)
      FactoryGirl.create(:lookup_annotation, annotation_report: ar)
      expect(ar.metrics[:trusted]).to eq(1)
    end
    it "should return trusted == 2 when there are 2 trusted annotations" do
      ar = FactoryGirl.create(:annotation_report)
      FactoryGirl.create(:lookup_annotation, annotation_report: ar)
      FactoryGirl.create(:lookup_annotation, annotation_report: ar)
      expect(ar.metrics[:trusted]).to eq(2)
    end
    it "should return distinct_trusted == 1 when are 2 indistinct trusted annotations" do
      ar = FactoryGirl.create(:annotation_report)
      FactoryGirl.create(:lookup_annotation, annotation_report: ar, annotated_string: "Some Text")
      FactoryGirl.create(:lookup_annotation, annotation_report: ar, annotated_string: "Some Text")
      expect(ar.metrics[:distinct_trusted]).to eq(1)
    end
    it "should return distinct_trusted == 2 when are 2 distinct trusted annotations" do
      ar = FactoryGirl.create(:annotation_report)
      FactoryGirl.create(:lookup_annotation, annotation_report: ar, annotated_string: "Some Text")
      FactoryGirl.create(:lookup_annotation, annotation_report: ar, annotated_string: "Some Other Text")
      expect(ar.metrics[:distinct_trusted]).to eq(2)
    end
    it "should return correct_trusted == 0 when there is 1 incorrect trusted annotation" do
      ar = FactoryGirl.create(:annotation_report)
      FactoryGirl.create(:lookup_annotation, annotation_report: ar, accepted: false)
      expect(ar.metrics[:correct_trusted]).to eq(0)
    end
    it "should return correct_trusted == 1 when there is 1 correct trusted annotation" do
      ar = FactoryGirl.create(:annotation_report)
      FactoryGirl.create(:lookup_annotation, annotation_report: ar, accepted: true)
      expect(ar.metrics[:correct_trusted]).to eq(1)
    end
    it "should return correct_trusted == 2 when there are 2 correct trusted annotations" do
      ar = FactoryGirl.create(:annotation_report)
      FactoryGirl.create(:lookup_annotation, annotation_report: ar, accepted: true)
      FactoryGirl.create(:lookup_annotation, annotation_report: ar, accepted: true)
      expect(ar.metrics[:correct_trusted]).to eq(2)
    end
    it "should return distinct_correct_trusted == 1 when there are 2 indistinct correct trusted annotations" do
      ar = FactoryGirl.create(:annotation_report)
      FactoryGirl.create(:lookup_annotation, annotation_report: ar, accepted: true, annotated_string: "SomeText")
      FactoryGirl.create(:lookup_annotation, annotation_report: ar, accepted: true, annotated_string: "SomeText")
      expect(ar.metrics[:distinct_correct_trusted]).to eq(1)
    end
    it "should return distinct_correct_trusted == 2 when there are 2 distinct correct trusted annotations" do
      ar = FactoryGirl.create(:annotation_report)
      FactoryGirl.create(
        :lookup_annotation, annotation_report: ar, accepted: true, annotated_string: "SomeText"
      )
      FactoryGirl.create(
        :lookup_annotation, annotation_report: ar, accepted: true, annotated_string: "SomeNewText"
      )
      expect(ar.metrics[:distinct_correct_trusted]).to eq(2)
    end
    it "should return distinct_correct_trusted == 2 when there are 2 distinct correct trusted annotations and a recognized annotation with the same text" do
      ar = FactoryGirl.create(:annotation_report)
      FactoryGirl.create(
        :annotation, annotation_report: ar, recognized_class: "RC", accepted: true, annotated_string: "SomeText"
      )
      FactoryGirl.create(
        :lookup_annotation, annotation_report: ar, accepted: true, annotated_string: "SomeText"
      )
      FactoryGirl.create(
        :lookup_annotation, annotation_report: ar, accepted: true, annotated_string: "SomeNewText"
      )
      expect(ar.metrics[:distinct_correct_trusted]).to eq(2)
    end
    it "should return lookup_edges == 0 when there are no annotations" do
      ar = FactoryGirl.create(:annotation_report)
      expect(ar.metrics[:lookup_edges]).to eq(0)
    end
    it "should return distinct_lookup_edges == 0 when there are no annotations" do
      ar = FactoryGirl.create(:annotation_report)
      expect(ar.metrics[:distinct_lookup_edges]).to eq(0)
    end
    it "should return correct_lookup_edges == 0 when there are no annotations" do
      ar = FactoryGirl.create(:annotation_report)
      expect(ar.metrics[:correct_lookup_edges]).to eq(0)
    end
    it "should return distinct_correct_lookup_edges == 0 when there are no annotations" do
      ar = FactoryGirl.create(:annotation_report)
      expect(ar.metrics[:distinct_correct_lookup_edges]).to eq(0)
    end
    it "should return same number of lookup edges as annotations with edges" do
      ar = FactoryGirl.create(:annotation_report)
      ann_1 = FactoryGirl.create(:lookup_annotation, annotation_report: ar, lookup_class: "LookupClass1", instance: "http://www.subtext.org/resource/Company_T.7687")
      edges_1 = AnnotationReport.filter_edges(ann_1.edges)
      ann_2 = FactoryGirl.create(:lookup_annotation, annotation_report: ar, lookup_class: "LookupClass2", instance: "http://www.subtext.org/resource/Company_T.7687")
      edges_2 = AnnotationReport.filter_edges(ann_2.edges)
      expect(ar.metrics[:lookup_edges]).to eq(edges_1.length + edges_2.length)
    end
    it "should return same number of distinct lookup edges as distinct (by lookup url ) annotations with edges" do
      ar = FactoryGirl.create(:annotation_report)
      ann_1 = FactoryGirl.create(:lookup_annotation, annotation_report: ar, lookup_class: "LookupClass1", instance: "http://www.subtext.org/resource/Company_T.7687")
      edges_1 = AnnotationReport.filter_edges(ann_1.edges)
      ann_2 = FactoryGirl.create(:lookup_annotation, annotation_report: ar, lookup_class: "LookupClass2", instance: "http://www.subtext.org/resource/Company_T.7687")
      edges_2 = AnnotationReport.filter_edges(ann_2.edges)
      expect(ar.metrics[:distinct_lookup_edges]).to eq(edges_1.length)
    end

  end

  describe "csv_report" do
    it "should contain a 'Name' header" do
      report = AnnotationReport.csv_report 12345
      expect(report).to include("Name")
    end
    it "should contain a 'Date' header" do
      report = AnnotationReport.csv_report 12345
      expect(report).to include("Date")
    end
    it "should contain a 'Total Recognized' header" do
      report = AnnotationReport.csv_report 12345
      expect(report).to include("Total Recognized")
    end
    it "should contain a 'Distinct Recognized' header" do
      report = AnnotationReport.csv_report 12345
      expect(report).to include("Distinct Recognized")
    end
    it "should contain a 'Correct Recognized' header" do
      report = AnnotationReport.csv_report 12345
      expect(report).to include("Correct Recognized")
    end
    it "should contain a 'Distinct Correct Recognized' header" do
      report = AnnotationReport.csv_report 12345
      expect(report).to include("Distinct Correct Recognized")
    end
    it "should contain a 'Total Lookups' header" do
      report = AnnotationReport.csv_report 12345
      expect(report).to include("Total Lookups")
    end
    it "should contain a 'Distinct Lookups' header" do
      report = AnnotationReport.csv_report 12345
      expect(report).to include("Distinct Lookups")
    end
    it "should contain a 'Correct Lookups' header" do
      report = AnnotationReport.csv_report 12345
      expect(report).to include("Correct Lookups")
    end
    it "should contain a 'Distinct Correct Lookups' header" do
      report = AnnotationReport.csv_report 12345
      expect(report).to include("Distinct Correct Lookups")
    end
    it "should contain a 'Total Additional Edges' header" do
      report = AnnotationReport.csv_report 12345
      expect(report).to include("Total Additional Edges")
    end
    it "should contain a 'Distinct Additional Edges' header" do
      report = AnnotationReport.csv_report 12345
      expect(report).to include("Distinct Additional Edges")
    end
    it "should contain a 'Correct Additional Edges' header" do
      report = AnnotationReport.csv_report 12345
      expect(report).to include("Correct Additional Edges")
    end
    it "should contain a 'Distinct Correct Additional Edges' header" do
      report = AnnotationReport.csv_report 12345
      expect(report).to include("Distinct Correct Additional Edges")
    end
    it "should contain report-specific information" do
      content = FactoryGirl.create :annotation_report, content_id: 123456, name: "Blarg"
      report = AnnotationReport.csv_report 123456
      expect(report).to include("Blarg")
    end
  end

end
