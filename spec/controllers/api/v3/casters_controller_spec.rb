# frozen_string_literal: true

require 'spec_helper'
require 'json'

describe Api::V3::CastersController, type: :controller do
  describe 'GET show' do
    subject! { get :show, params: params }
    let(:params) { {} }

    describe 'for a non-existent caster' do
      it 'should respond with 404' do
        expect(response.status).to eql 404
      end
    end

    describe 'for an archived caster' do
      let!(:caster) { FactoryGirl.create :caster, archived: true, handle: 'fake-handle' }
      let(:params) { { handle: caster.handle } }

      it 'should respond with 404' do
        expect(response.status).to eql 404
      end
    end

    describe 'for an existing caster' do
      let!(:caster) { FactoryGirl.create :caster, handle: 'fake-handle' }

      describe 'querying by id' do
        let(:params) { { id: caster.id } }

        it 'should assign the caster' do
          expect(assigns(:caster)).to eql caster
        end
      end

      describe 'querying by handle' do
        let(:params) { { handle: caster.handle } }

        it 'should assign the caster' do
          expect(assigns(:caster)).to eql caster
        end
      end
    end
  end

  describe 'GET index' do
    subject! { get :index, params: params }
    let(:params) { {} }
  end
end
