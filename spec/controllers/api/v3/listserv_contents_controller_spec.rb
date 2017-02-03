require 'spec_helper'

RSpec.describe Api::V3::ListservContentsController, type: :controller do
  describe "POST #update_metric" do
    before do
      @listserv_content = FactoryGirl.create :listserv_content
      @params = {
        id: @listserv_content.key,
        enhance_link_clicked: true,
        post_type: 'event',
        step_reached: 'email_sent'
      }
    end

    subject { post :update_metric, @params }

    it "makes call to RecordListservMetric" do
      expect(RecordListservMetric).to receive(:call).with(
        'update_metric', @listserv_content,
        enhance_link_clicked: true,
        post_type: 'event',
        step_reached: 'email_sent'
      )
      subject
    end
  end
end