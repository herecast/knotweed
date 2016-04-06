require 'spec_helper'

describe AnnotationReportsController do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
  end

  describe 'GET /annotation_reports/:id/edit' do
    before do
      @annotation_report = FactoryGirl.create :annotation_report
    end

    subject { get(:edit, id: @annotation_report.id, :format => "js") }

    it "should respond with 200 status code" do
      subject
      response.code.should eq '200'
    end
  end

  describe 'GET /annotation_reports/:id/table_row' do
    before do
      @annotation_report = FactoryGirl.create :annotation_report
    end

    subject { get :table_row, id: @annotation_report.id }

    it "shoud respond with 200 status code" do
      subject
      response.code.should eq '200'
    end
  end

  describe 'DELETE /annotation_reports/:id' do
    before do
      @annotation_report = FactoryGirl.create :annotation_report
    end

    subject { delete :destroy, id: @annotation_report.id }

    it "should delete annotation report" do
      expect{ subject }.to change{ AnnotationReport.count }.by(-1)
    end
  end

  describe 'GET /annotation_reports/export/:content_id' do
    before do
      @annotation_report = FactoryGirl.create :annotation_report
    end

    subject { get(:export, content_id: @annotation_report.id, :format => "csv") }

    it "should respond with 200 status code" do
      subject
      response.code.should eq '200'
    end
  end
end
