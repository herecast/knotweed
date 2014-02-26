require 'spec_helper'

describe AnnotationReport do
  describe "metrics" do
    it "should return recognized == 0 when there are no annotations" do
      ar = FactoryGirl.create(:annotation_report)
      ar.metrics["recognized"].should== 0
    end
    it "should return distinct_recognized == 0 when there are no annotations" do
      ar = FactoryGirl.create(:annotation_report)
      ar.metrics["distinct_recognized"].should== 0
    end
    it "should return correct_recognized == 0 when there are no annotations" do
      ar = FactoryGirl.create(:annotation_report)
      ar.metrics["correct_recognized"].should== 0
    end
    it "should return distinct_correct_recognized == 0 when there are no annotations" do
      ar = FactoryGirl.create(:annotation_report)
      ar.metrics["distinct_correct_recognized"].should== 0
    end
    it "should return trusted == 0 when there are no annotations" do
      ar = FactoryGirl.create(:annotation_report)
      ar.metrics["trusted"].should== 0
    end
    it "should return distinct_trusted == 0 when there are no annotations" do
      ar = FactoryGirl.create(:annotation_report)
      ar.metrics["distinct_trusted"].should== 0
    end
    it "should return correct_trusted == 0 when there are no annotations" do
      ar = FactoryGirl.create(:annotation_report)
      ar.metrics["correct_trusted"].should== 0
    end
    it "should return distinct_correct_trusted == 0 when there are no annotations" do
      ar = FactoryGirl.create(:annotation_report)
      ar.metrics["distinct_correct_trusted"].should== 0
    end
    it "should return recognized == 1 when there is 1 recognized annotation" do
      ar = FactoryGirl.create(:annotation_report)
      ann = FactoryGirl.create(:annotation, annotation_report: ar, recognized_class: "SomeNonemptyValue")
      ar.metrics["recognized"].should== 1
    end
    it "should return recognized == 2 when there are 2 recognized annotations" do
      ar = FactoryGirl.create(:annotation_report)
      ann_1 = FactoryGirl.create(:annotation, annotation_report: ar, recognized_class: "SomeNonemptyValue")
      ann_2 = FactoryGirl.create(:annotation, annotation_report: ar, recognized_class: "SomeOtherNonemptyValue")
      ar.metrics["recognized"].should== 2
    end
    it "should return recognized == 0 when there is 1 trusted annotation" do
      ar = FactoryGirl.create(:annotation_report)
      ann = FactoryGirl.create(
        :annotation,
        annotation_report: ar,
        recognized_class: "SomeNonemptyValue",
        lookup_class: "LookupClassValue"
      )
      ar.metrics["recognized"].should== 0
    end
    it "should return distinct_recognized == 1 when there are 2 indistinct recognized annotations" do
      ar = FactoryGirl.create(:annotation_report)
      ann_1 = FactoryGirl.create(:annotation, annotation_report: ar, recognized_class: "SomeNonemptyValue", annotated_string: "SomeText")
      ann_2 = FactoryGirl.create(:annotation, annotation_report: ar, recognized_class: "SomeOtherNonemptyValue", annotated_string: "SomeText")
      ar.metrics["distinct_recognized"].should== 1
    end
    it "should return distinct_recognized == 2 when there are 2 distinct recognized annotations" do
      ar = FactoryGirl.create(:annotation_report)
      ann_1 = FactoryGirl.create(:annotation, annotation_report: ar, recognized_class: "SomeNonemptyValue", annotated_string: "SomeText")
      ann_2 = FactoryGirl.create(:annotation, annotation_report: ar, recognized_class: "SomeOtherNonemptyValue", annotated_string: "SomeNewText")
      ar.metrics["distinct_recognized"].should== 2
    end
    it "should return correct_recognized == 0 when there is 1 incorrect recognized annotation" do
      ar = FactoryGirl.create(:annotation_report)
      ann = FactoryGirl.create(:annotation, annotation_report: ar, recognized_class: "SomeNonemptyValue", accepted: false )
      ar.metrics["correct_recognized"].should== 0
    end
    it "should return correct_recognized == 1 when there is 1 correct recognized annotation" do
      ar = FactoryGirl.create(:annotation_report)
      ann = FactoryGirl.create(:annotation, annotation_report: ar, recognized_class: "SomeNonemptyValue", accepted: true )
      ar.metrics["correct_recognized"].should== 1
    end
    it "should return correct_recognized == 2 when there is 2 correct recognized annotations" do
      ar = FactoryGirl.create(:annotation_report)
      ann_1 = FactoryGirl.create(:annotation, annotation_report: ar, recognized_class: "SomeNonemptyValue", accepted: true )
      ann_2 = FactoryGirl.create(:annotation, annotation_report: ar, recognized_class: "SomeNonemptyValue", accepted: true )
      ar.metrics["correct_recognized"].should== 2
    end
    it "should return distinct_correct_recognized == 1 when there is 2 indistinct correct recognized annotations" do
      ar = FactoryGirl.create(:annotation_report)
      ann_1 = FactoryGirl.create(
        :annotation, annotation_report: ar, recognized_class: "SomeNonemptyValue", accepted: true, annotated_string: "SomeText"
      )
      ann_2 = FactoryGirl.create(
        :annotation, annotation_report: ar, recognized_class: "SomeNonemptyValue", accepted: true, annotated_string: "SomeText"
      )
      ar.metrics["distinct_correct_recognized"].should== 1
    end
    it "should return trusted == 1 when there is 1 trusted annotation" do
      ar = FactoryGirl.create(:annotation_report)
      ann = FactoryGirl.create(:annotation, annotation_report: ar, lookup_class: "SomeLookupClass")
      ar.metrics["trusted"].should== 1
    end
    it "should return trusted == 2 when there are 2 trusted annotations" do
      ar = FactoryGirl.create(:annotation_report)
      FactoryGirl.create(:annotation, annotation_report: ar, lookup_class: "SomeLookupClass")
      FactoryGirl.create(:annotation, annotation_report: ar, lookup_class: "SomeLookupClass")
      ar.metrics["trusted"].should== 2
    end
    it "should return distinct_trusted == 1 when are 2 indistinct trusted annotations" do
      ar = FactoryGirl.create(:annotation_report)
      FactoryGirl.create(:annotation, annotation_report: ar, lookup_class: "SomeLookupClass", annotated_string: "Some Text")
      FactoryGirl.create(:annotation, annotation_report: ar, lookup_class: "SomeLookupClass", annotated_string: "Some Text")
      ar.metrics["distinct_trusted"].should== 1
    end
    it "should return distinct_trusted == 2 when are 2 distinct trusted annotations" do
      ar = FactoryGirl.create(:annotation_report)
      FactoryGirl.create(:annotation, annotation_report: ar, lookup_class: "SomeLookupClass", annotated_string: "Some Text")
      FactoryGirl.create(:annotation, annotation_report: ar, lookup_class: "SomeLookupClass", annotated_string: "Some Other Text")
      ar.metrics["distinct_trusted"].should== 2
    end
    it "should return correct_trusted == 0 when there is 1 incorrect trusted annotation" do
      ar = FactoryGirl.create(:annotation_report)
      ann = FactoryGirl.create(:annotation, annotation_report: ar, lookup_class: "SomeLookupClass", accepted: false)
      ar.metrics["correct_trusted"].should== 0
    end
    it "should return correct_trusted == 1 when there is 1 correct trusted annotation" do
      ar = FactoryGirl.create(:annotation_report)
      ann = FactoryGirl.create(:annotation, annotation_report: ar, lookup_class: "SomeLookupClass", accepted: true)
      ar.metrics["correct_trusted"].should== 1
    end
    it "should return correct_trusted == 2 when there are 2 correct trusted annotations" do
      ar = FactoryGirl.create(:annotation_report)
      ann = FactoryGirl.create(:annotation, annotation_report: ar, lookup_class: "SomeLookupClass", accepted: true)
      ann = FactoryGirl.create(:annotation, annotation_report: ar, lookup_class: "SomeLookupClass", accepted: true)
      ar.metrics["correct_trusted"].should== 2
    end
    it "should return distinct_correct_trusted == 1 when there are 2 indistinct correct trusted annotations" do
      ar = FactoryGirl.create(:annotation_report)
      ann = FactoryGirl.create(:annotation, annotation_report: ar, lookup_class: "SomeLookupClass", accepted: true, annotated_string: "SomeText")
      ann = FactoryGirl.create(:annotation, annotation_report: ar, lookup_class: "SomeLookupClass", accepted: true, annotated_string: "SomeText")
      ar.metrics["distinct_correct_trusted"].should== 1
    end
    it "should return distinct_correct_trusted == 2 when there are 2 distinct correct trusted annotations" do
      ar = FactoryGirl.create(:annotation_report)
      ann = FactoryGirl.create(
        :annotation, annotation_report: ar, lookup_class: "SomeLookupClass", accepted: true, annotated_string: "SomeText"
      )
      ann = FactoryGirl.create(
        :annotation, annotation_report: ar, lookup_class: "SomeLookupClass", accepted: true, annotated_string: "SomeNewText"
      )
      ar.metrics["distinct_correct_trusted"].should== 2
    end

  end
end
