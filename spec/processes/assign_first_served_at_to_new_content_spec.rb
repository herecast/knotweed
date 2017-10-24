require 'rails_helper'

RSpec.describe AssignFirstServedAtToNewContent do
  RSpec::Matchers.define_negated_matcher :not_change, :change

  describe '::call' do
    before do
      @content_one = FactoryGirl.create :content
      @content_two = FactoryGirl.create :content,
        first_served_at: Date.yesterday
      @current_time = Time.current.to_s
    end

    subject do
      AssignFirstServedAtToNewContent.call(
        content_ids: [@content_one.id, @content_two.id],
        current_time: @current_time
      )
    end

    it "updates first_served_at for previously unserved content item" do
      expect{ subject }.to change{
        @content_one.reload.first_served_at.to_s
      }.to(@current_time).and not_change{
        @content_two.reload.first_served_at
      }
    end
  end
end