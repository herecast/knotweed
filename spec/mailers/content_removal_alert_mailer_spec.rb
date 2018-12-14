# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContentRemovalAlertMailer do
  subject { ContentRemovalAlertMailer.content_removal_alert(@content).deliver_now }

  context 'when content is a post' do
    before do
      @content = FactoryGirl.create :content, :news
    end

    it 'delivers mail' do
      expect { subject }.to change {
        ActionMailer::Base.deliveries.count
      }.by(1)
    end

    it 'includes title as link to the parent content' do
      expect(subject.body).to include @content.title
    end
  end

  context 'when content is a comment' do
    before do
      @content = FactoryGirl.create :content, :comment
    end

    it 'delivers mail' do
      expect { subject }.to change {
        ActionMailer::Base.deliveries.count
      }.by(1)
    end

    it 'includes comment as link to the parent content' do
      expect(subject.body).to include @content.content
    end
  end
end
