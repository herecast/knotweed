require 'spec_helper'

describe AnnotationReportsController, type: :controller do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
  end

  describe 'POST #create' do
    before do
      @repository = FactoryGirl.create :repository
      @content = FactoryGirl.create :content
      @data = { content_id: @content.id, repository_id: @repository.id }
    end

    subject { post :create, @data }

    context "when annotation report is created" do
      it "should respond with 200 status code" do
        hash = { "annotation-sets" => [{ "annotation" => [] }] }.to_json
        OntotextController.stub(:get_annotations) { '{ "results": { "bindings": [{ "annotation": { "value": "' + hash + '" } }] } }' }
        subject
      end
    end
  end

  describe 'GET #edit' do
    before do
      @annotation_report = FactoryGirl.create :annotation_report
    end

    subject { get(:edit, id: @annotation_report.id, :format => "js") }

    it "should respond with 200 status code" do
      subject
      expect(response.code).to eq '200'
    end
  end

  describe 'GET #table_row' do
    before do
      @annotation_report = FactoryGirl.create :annotation_report
    end

    subject { get :table_row, id: @annotation_report.id }

    it "shoud respond with 200 status code" do
      subject
      expect(response.code).to eq '200'
    end
  end

  describe 'DELETE #destroy' do
    before do
      @annotation_report = FactoryGirl.create :annotation_report
    end

    subject { delete :destroy, id: @annotation_report.id }

    it "should delete annotation report" do
      expect{ subject }.to change{ AnnotationReport.count }.by(-1)
    end
  end

  describe 'GET #export' do
    before do
      @annotation_report = FactoryGirl.create :annotation_report
    end

    subject { get(:export, content_id: @annotation_report.id, :format => "csv") }

    it "should respond with 200 status code" do
      subject
      expect(response.code).to eq '200'
    end
  end
end
