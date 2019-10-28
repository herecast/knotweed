# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Caster Emails endpoint', type: :request do
  describe "/api/v3/casters/emails/validation" do
    context "when email does not exist" do
      subject { get '/api/v3/casters/emails/validation?email=some@fake.email' }

      it "returns not found status" do
        subject
        expect(response).to have_http_status :not_found
      end
    end

    context "when email exists" do
      before do
        @email = 'some@fake.email'
        FactoryGirl.create :user, email: @email
      end

      subject { get "/api/v3/casters/emails/validation?email=#{@email}" }

      it "returns ok status" do
        subject
        expect(response).to have_http_status :ok
      end
    end
  end
end