require 'spec_helper'

describe AnnotationReport do
  describe "metrics" do
    it "should return recognized == 0 when there are no annotations" do
      ar = FactoryGirl.create(:annotation_report)
      ar.metrics[:recognized].should== 0
    end
    it "should return distinct_recognized == 0 when there are no annotations" do
      ar = FactoryGirl.create(:annotation_report)
      ar.metrics[:distinct_recognized].should== 0
    end
    it "should return correct_recognized == 0 when there are no annotations" do
      ar = FactoryGirl.create(:annotation_report)
      ar.metrics[:correct_recognized].should== 0
    end
    it "should return distinct_correct_recognized == 0 when there are no annotations" do
      ar = FactoryGirl.create(:annotation_report)
      ar.metrics[:distinct_correct_recognized].should== 0
    end
    it "should return trusted == 0 when there are no annotations" do
      ar = FactoryGirl.create(:annotation_report)
      ar.metrics[:trusted].should== 0
    end
    it "should return distinct_trusted == 0 when there are no annotations" do
      ar = FactoryGirl.create(:annotation_report)
      ar.metrics[:distinct_trusted].should== 0
    end
    it "should return correct_trusted == 0 when there are no annotations" do
      ar = FactoryGirl.create(:annotation_report)
      ar.metrics[:correct_trusted].should== 0
    end
    it "should return distinct_correct_trusted == 0 when there are no annotations" do
      ar = FactoryGirl.create(:annotation_report)
      ar.metrics[:distinct_correct_trusted].should== 0
    end
    it "should return recognized == 1 when there is 1 recognized annotation" do
      ar = FactoryGirl.create(:annotation_report)
      FactoryGirl.create(:annotation, annotation_report: ar, recognized_class: "SomeNonemptyValue")
      ar.metrics[:recognized].should== 1
    end
    it "should return recognized == 2 when there are 2 recognized annotations" do
      ar = FactoryGirl.create(:annotation_report)
      FactoryGirl.create(:annotation, annotation_report: ar, recognized_class: "SomeNonemptyValue")
      FactoryGirl.create(:annotation, annotation_report: ar, recognized_class: "SomeOtherNonemptyValue")
      ar.metrics[:recognized].should== 2
    end
    it "should return recognized == 0 when there is 1 trusted annotation" do
      ar = FactoryGirl.create(:annotation_report)
      FactoryGirl.create(
        :annotation,
        annotation_report: ar,
        recognized_class: "SomeNonemptyValue",
        lookup_class: "LookupClassValue",
        is_generated: false
      )
      ar.metrics[:recognized].should== 0
    end
    it "should return distinct_recognized == 1 when there are 2 indistinct recognized annotations" do
      ar = FactoryGirl.create(:annotation_report)
      FactoryGirl.create(:annotation, annotation_report: ar, recognized_class: "SomeNonemptyValue", annotated_string: "SomeText")
      FactoryGirl.create(:annotation, annotation_report: ar, recognized_class: "SomeOtherNonemptyValue", annotated_string: "SomeText")
      ar.metrics[:distinct_recognized].should== 1
    end
    it "should return distinct_recognized == 2 when there are 2 distinct recognized annotations" do
      ar = FactoryGirl.create(:annotation_report)
      FactoryGirl.create(:annotation, annotation_report: ar, recognized_class: "SomeNonemptyValue", annotated_string: "SomeText")
      FactoryGirl.create(:annotation, annotation_report: ar, recognized_class: "SomeOtherNonemptyValue", annotated_string: "SomeNewText")
      ar.metrics[:distinct_recognized].should== 2
    end
    it "should return correct_recognized == 0 when there is 1 incorrect recognized annotation" do
      ar = FactoryGirl.create(:annotation_report)
      FactoryGirl.create(:annotation, annotation_report: ar, recognized_class: "SomeNonemptyValue", accepted: false )
      ar.metrics[:correct_recognized].should== 0
    end
    it "should return correct_recognized == 1 when there is 1 correct recognized annotation" do
      ar = FactoryGirl.create(:annotation_report)
      FactoryGirl.create(:annotation, annotation_report: ar, recognized_class: "SomeNonemptyValue", accepted: true )
      ar.metrics[:correct_recognized].should== 1
    end
    it "should return correct_recognized == 2 when there is 2 correct recognized annotations" do
      ar = FactoryGirl.create(:annotation_report)
      FactoryGirl.create(:annotation, annotation_report: ar, recognized_class: "SomeNonemptyValue", accepted: true )
      FactoryGirl.create(:annotation, annotation_report: ar, recognized_class: "SomeNonemptyValue", accepted: true )
      ar.metrics[:correct_recognized].should== 2
    end
    it "should return distinct_correct_recognized == 1 when there is 2 indistinct correct recognized annotations" do
      ar = FactoryGirl.create(:annotation_report)
      FactoryGirl.create(
        :annotation, annotation_report: ar, recognized_class: "SomeNonemptyValue", accepted: true, annotated_string: "SomeText"
      )
      FactoryGirl.create(
        :annotation, annotation_report: ar, recognized_class: "SomeNonemptyValue", accepted: true, annotated_string: "SomeText"
      )
      ar.metrics[:distinct_correct_recognized].should== 1
    end
    it "should return trusted == 1 when there is 1 trusted annotation" do
      ar = FactoryGirl.create(:annotation_report)
      FactoryGirl.create(:annotation, annotation_report: ar, lookup_class: "SomeLookupClass", is_generated: false)
      ar.metrics[:trusted].should== 1
    end
    it "should return trusted == 2 when there are 2 trusted annotations" do
      ar = FactoryGirl.create(:annotation_report)
      FactoryGirl.create(:annotation, annotation_report: ar, lookup_class: "SomeLookupClass", is_generated: false)
      FactoryGirl.create(:annotation, annotation_report: ar, lookup_class: "SomeLookupClass", is_generated: false)
      ar.metrics[:trusted].should== 2
    end
    it "should return distinct_trusted == 1 when are 2 indistinct trusted annotations" do
      ar = FactoryGirl.create(:annotation_report)
      FactoryGirl.create(:annotation, annotation_report: ar, lookup_class: "SomeLookupClass", is_generated: false, annotated_string: "Some Text")
      FactoryGirl.create(:annotation, annotation_report: ar, lookup_class: "SomeLookupClass", is_generated: false, annotated_string: "Some Text")
      ar.metrics[:distinct_trusted].should== 1
    end
    it "should return distinct_trusted == 2 when are 2 distinct trusted annotations" do
      ar = FactoryGirl.create(:annotation_report)
      FactoryGirl.create(:annotation, annotation_report: ar, lookup_class: "SomeLookupClass", is_generated: false, annotated_string: "Some Text")
      FactoryGirl.create(:annotation, annotation_report: ar, lookup_class: "SomeLookupClass", is_generated: false, annotated_string: "Some Other Text")
      ar.metrics[:distinct_trusted].should== 2
    end
    it "should return correct_trusted == 0 when there is 1 incorrect trusted annotation" do
      ar = FactoryGirl.create(:annotation_report)
      FactoryGirl.create(:annotation, annotation_report: ar, lookup_class: "SomeLookupClass", accepted: false, is_generated: false)
      ar.metrics[:correct_trusted].should== 0
    end
    it "should return correct_trusted == 1 when there is 1 correct trusted annotation" do
      ar = FactoryGirl.create(:annotation_report)
      FactoryGirl.create(:annotation, annotation_report: ar, lookup_class: "SomeLookupClass", accepted: true, is_generated: false)
      ar.metrics[:correct_trusted].should== 1
    end
    it "should return correct_trusted == 2 when there are 2 correct trusted annotations" do
      ar = FactoryGirl.create(:annotation_report)
      FactoryGirl.create(:annotation, annotation_report: ar, lookup_class: "SomeLookupClass", accepted: true, is_generated: false)
      FactoryGirl.create(:annotation, annotation_report: ar, lookup_class: "SomeLookupClass", accepted: true, is_generated: false)
      ar.metrics[:correct_trusted].should== 2
    end
    it "should return distinct_correct_trusted == 1 when there are 2 indistinct correct trusted annotations" do
      ar = FactoryGirl.create(:annotation_report)
      FactoryGirl.create(:annotation, annotation_report: ar, lookup_class: "SomeLookupClass", accepted: true, annotated_string: "SomeText", is_generated: false)
      FactoryGirl.create(:annotation, annotation_report: ar, lookup_class: "SomeLookupClass", accepted: true, annotated_string: "SomeText", is_generated: false)
      ar.metrics[:distinct_correct_trusted].should== 1
    end
    it "should return distinct_correct_trusted == 2 when there are 2 distinct correct trusted annotations" do
      ar = FactoryGirl.create(:annotation_report)
      FactoryGirl.create(
        :annotation, annotation_report: ar, lookup_class: "SomeLookupClass", accepted: true, annotated_string: "SomeText", is_generated: false
      )
      FactoryGirl.create(
        :annotation, annotation_report: ar, lookup_class: "SomeLookupClass", accepted: true, annotated_string: "SomeNewText", is_generated: false
      )
      ar.metrics[:distinct_correct_trusted].should== 2
    end
    it "should return distinct_correct_trusted == 2 when there are 2 distinct correct trusted annotations and a recognized annotation with the same text" do
      ar = FactoryGirl.create(:annotation_report)
      FactoryGirl.create(
        :annotation, annotation_report: ar, recognized_class: "RC", accepted: true, annotated_string: "SomeText"
      )
      FactoryGirl.create(
        :annotation, annotation_report: ar, lookup_class: "SomeLookupClass", accepted: true, annotated_string: "SomeText", is_generated: false
      )
      FactoryGirl.create(
        :annotation, annotation_report: ar, lookup_class: "SomeLookupClass", accepted: true, annotated_string: "SomeNewText", is_generated: false
      )
      ar.metrics[:distinct_correct_trusted].should== 2
    end
    it "should return lookup_edges == 0 when there are no annotations" do
      ar = FactoryGirl.create(:annotation_report)
      ar.metrics[:lookup_edges].should== 0
    end
    it "should return distinct_lookup_edges == 0 when there are no annotations" do
      ar = FactoryGirl.create(:annotation_report)
      ar.metrics[:distinct_lookup_edges].should== 0
    end
    it "should return correct_lookup_edges == 0 when there are no annotations" do
      ar = FactoryGirl.create(:annotation_report)
      ar.metrics[:correct_lookup_edges].should== 0
    end
    it "should return distinct_correct_lookup_edges == 0 when there are no annotations" do
      ar = FactoryGirl.create(:annotation_report)
      ar.metrics[:distinct_correct_lookup_edges].should== 0
    end
    it "should return same number of lookup edges as annotations with edges" do
      ar = FactoryGirl.create(:annotation_report)
      ann_1 = FactoryGirl.create(:annotation, annotation_report: ar, lookup_class: "LookupClass1", instance: "http://www.subtext.org/resource/Company_T.7687", is_generated: false)
      edges_1 = AnnotationReport.filter_edges(ann_1.edges)
      ann_2 = FactoryGirl.create(:annotation, annotation_report: ar, lookup_class: "LookupClass2", instance: "http://www.subtext.org/resource/Company_T.7687", is_generated: false)
      edges_2 = AnnotationReport.filter_edges(ann_2.edges)
      ar.metrics[:lookup_edges].should== edges_1.length + edges_2.length
    end
    it "should return same number of distinct lookup edges as distinct (by lookup url ) annotations with edges" do
      ar = FactoryGirl.create(:annotation_report)
      ann_1 = FactoryGirl.create(:annotation, annotation_report: ar, lookup_class: "LookupClass1", instance: "http://www.subtext.org/resource/Company_T.7687", is_generated: false)
      edges_1 = AnnotationReport.filter_edges(ann_1.edges)
      ann_2 = FactoryGirl.create(:annotation, annotation_report: ar, lookup_class: "LookupClass2", instance: "http://www.subtext.org/resource/Company_T.7687", is_generated: false)
      edges_2 = AnnotationReport.filter_edges(ann_2.edges)
      ar.metrics[:distinct_lookup_edges].should== edges_1.length
    end

  end

  describe "csv_report" do
    it "should contain a 'Name' header" do
      report = AnnotationReport.csv_report 12345
      report.should include("Name")
    end
    it "should contain a 'Date' header" do
      report = AnnotationReport.csv_report 12345
      report.should include("Date")
    end
    it "should contain a 'Total Recognized' header" do
      report = AnnotationReport.csv_report 12345
      report.should include("Total Recognized")
    end
    it "should contain a 'Distinct Recognized' header" do
      report = AnnotationReport.csv_report 12345
      report.should include("Distinct Recognized")
    end
    it "should contain a 'Correct Recognized' header" do
      report = AnnotationReport.csv_report 12345
      report.should include("Correct Recognized")
    end
    it "should contain a 'Distinct Correct Recognized' header" do
      report = AnnotationReport.csv_report 12345
      report.should include("Distinct Correct Recognized")
    end
    it "should contain a 'Total Lookups' header" do
      report = AnnotationReport.csv_report 12345
      report.should include("Total Lookups")
    end
    it "should contain a 'Distinct Lookups' header" do
      report = AnnotationReport.csv_report 12345
      report.should include("Distinct Lookups")
    end
    it "should contain a 'Correct Lookups' header" do
      report = AnnotationReport.csv_report 12345
      report.should include("Correct Lookups")
    end
    it "should contain a 'Distinct Correct Lookups' header" do
      report = AnnotationReport.csv_report 12345
      report.should include("Distinct Correct Lookups")
    end
    it "should contain a 'Total Additional Edges' header" do
      report = AnnotationReport.csv_report 12345
      report.should include("Total Additional Edges")
    end
    it "should contain a 'Distinct Additional Edges' header" do
      report = AnnotationReport.csv_report 12345
      report.should include("Distinct Additional Edges")
    end
    it "should contain a 'Correct Additional Edges' header" do
      report = AnnotationReport.csv_report 12345
      report.should include("Correct Additional Edges")
    end
    it "should contain a 'Distinct Correct Additional Edges' header" do
      report = AnnotationReport.csv_report 12345
      report.should include("Distinct Correct Additional Edges")
    end


  end

end
