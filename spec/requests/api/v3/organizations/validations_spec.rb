# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Organizations::Validations', type: :request do
  describe 'GET show' do
    context 'when no Organization present with name' do
      subject { get '/api/v3/organizations/fakey-jakey/validation' }

      it 'returns ok status' do
        subject
        expect(response).to have_http_status :ok
      end
    end

    context 'when organization exists with name' do
      before do
        @name = "Darth's Memoirs"
        FactoryGirl.create :organization, name: @name
      end

      subject { get "/api/v3/organizations/#{URI.encode(@name)}/validation" }

      it 'returns not acceptable status' do
        subject
        expect(response).to have_http_status :not_acceptable
      end
    end
  end
end
