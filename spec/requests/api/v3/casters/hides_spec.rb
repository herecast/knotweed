# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Caster Hides Endpoints', type: :request do
  let(:caster) { FactoryGirl.create :caster }
  let(:user) { FactoryGirl.create :user }
  let(:headers) { auth_headers_for(user) }
  let(:params) { { caster_hide: { flag_type: 'Spammy' } } }

  describe 'POST /api/v3/casters/:caster_id/hides' do
    subject do
      post "/api/v3/casters/#{caster.id}/hides",
           headers: headers,
           params: params
    end

    it 'creates CasterHide' do
      expect { subject }.to change {
        CasterHide.count
      }.by 1
    end

    context 'when CasterHide exists but deleted_at is not null' do
      before do
        @caster_hide = FactoryGirl.create :caster_hide,
                                       user_id: user.id,
                                       caster_id: caster.id,
                                       deleted_at: Date.yesterday
      end

      it 'does not create new CasterHide' do
        expect { subject }.not_to change {
          CasterHide.count
        }
      end

      it 'updates deleted_at to nil' do
        expect { subject }.to change {
          @caster_hide.reload.deleted_at
        }.to nil
      end
    end
  end

  describe 'DELETE /api/v3/casters/hides/:id' do
    before do
      @caster_hide = FactoryGirl.create :caster_hide,
                                     user_id: user.id,
                                     deleted_at: nil
    end

    subject do
      delete "/api/v3/casters/hides/#{@caster_hide.id}",
             headers: headers
    end

    it 'updates deleted_at to current time' do
      expect { subject }.to change {
        @caster_hide.reload.deleted_at
      }
    end
  end
end
