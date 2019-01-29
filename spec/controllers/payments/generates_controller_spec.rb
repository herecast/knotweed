# frozen_string_literal: true

require 'spec_helper'

describe Payments::GeneratesController, type: :controller do
  let(:admin) { FactoryGirl.create :admin }
  before { sign_in admin }

  describe 'POST #create' do
    let(:period_start) { 2.weeks.ago.strftime('%m/%d/%Y') }
    let(:period_end) { Date.today.strftime('%m/%d/%Y') }
    let(:period_ad_rev) { "1500.57" }

    subject { post :create, params: {
      period_start: period_start, period_end: period_end, period_ad_rev: period_ad_rev
    } }

    it 'should queue GeneratePaymentsJob' do
      subject
      expect(GeneratePaymentsJob).to have_been_enqueued.with(period_start, period_end, period_ad_rev)
    end
  end

  describe 'GET #new' do
    it 'should respond with 200' do
      subject
      expect(response.status).to eq 200
    end
  end
end
