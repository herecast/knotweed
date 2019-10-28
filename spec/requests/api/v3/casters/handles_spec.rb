# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Caster Handles endpoint', type: :request do
  describe "/api/v3/casters/handles/validation" do
    context "when handle does not exist" do
      subject { get '/api/v3/casters/handles/validation?handle=fake-handle' }

      it "returns not found status" do
        subject
        expect(response).to have_http_status :not_found
      end
    end

    context "when handle exists" do
      before do
        @handle = 'fake-handle'
        FactoryGirl.create :user, handle: @handle
      end

      subject { get "/api/v3/casters/handles/validation?handle=#{@handle}" }

      it "returns ok status" do
        subject
        expect(response).to have_http_status :ok
      end
    end
  end
end