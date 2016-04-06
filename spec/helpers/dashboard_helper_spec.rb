require 'spec_helper'

describe DashboardHelper, type: :helper do
  describe '#yesterday_signed_in_percentage' do
    context 'Given a metrics data set' do
      let(:metrics) do 
        {
          total_users: 109,
          sign_ins: {
            yesterday: 12
          }
        }
      end

      subject { helper.yesterday_signed_in_percentage(metrics) }

      it 'figures % from yesterday\'s signins by total user count' do
        expect(subject).to eq ((12/109.to_f) * 100).to_i
      end
    end
  end
end
