require 'spec_helper'

describe AnnotationsController do
  let!(:annotation) { FactoryGirl.create :annotation }
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
    request.env['HTTP_REFERER'] = 'where_i_came_from'
  end

  context '#edit' do
    subject! do
      get :edit, annotation_report_id: annotation.annotation_report.id, annotation_id: annotation.annotation_id
    end

    it 'should return the correct annotation' do
      expect(assigns(:annotation).id).to eq annotation.id
    end
  end

  context '#accept_annotation' do
    subject do
      put :accept_annotation, id: annotation.id, accepted: '1', format: :js
    end

    it 'should change accepted to true' do
      expect{subject}.to change{annotation.reload.accepted}.from(false).to(true)
    end

    it 'should set other variables' do
      subject
      expect(assigns(:annotation).id).to eq annotation.id
      expect(assigns(:annotation_report)).to eq annotation.annotation_report
    end
  end

end
