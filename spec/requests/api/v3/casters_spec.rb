# frozen_string_literal: true

require 'rails_helper'

describe 'Casters endpoints', type: :request do

  describe 'GET /api/v3/casters/follows', elasticsearch: true do
    before do
      @query = 'Han'
      @caster = FactoryGirl.create :caster, handle: @query
      Caster.reindex
    end

    subject { get "/api/v3/casters/follows?query=#{@query}" }

    it 'returns caster' do
      subject
      returned_caster_ids = JSON.parse(response.body)['casters'].map { |caster| caster['id'] }
      expect(returned_caster_ids).to match_array [@caster.id]
    end
  end

  describe "GET /api/v3/casters" do
    before do
      @handle = 'el-luke'
      @caster = FactoryGirl.create :caster, handle: @handle 
    end

    describe "/:id" do
      subject { get "/api/v3/casters/#{@caster.id}" }

      it "returns caster" do
        subject
        expect(JSON.parse(response.body)['caster']['id']).to eq @caster.id
      end
    end

    describe "?handle=<handle>" do
      subject { get "/api/v3/casters?handle=#{@handle}" }

      it "returns caster" do
        subject
        expect(JSON.parse(response.body)['caster']['id']).to eq @caster.id
      end
    end
  end
end
