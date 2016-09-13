require 'rails_helper'

RSpec.describe Api::V3::EmailsController, type: :controller do
  describe '#create' do
    context 'given valid params' do
      subject {
        post :create, {file_uri: 'http://path.local/to/file'}
      }

      it 'triggers ProcessReceivedEmailJob' do
        expect(ProcessReceivedEmailJob).to receive(:perform_later).with(instance_of(ReceivedEmail))
        subject
      end
    end
  end
end
