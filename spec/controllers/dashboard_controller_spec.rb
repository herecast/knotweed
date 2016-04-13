require 'spec_helper'

describe DashboardController, :type => :controller do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
  end

  describe 'GET index' do
    subject { get :index }

    it 'should respond with 200 status code' do
      subject
      expect(response.code).to eq '200'
    end
  end

  describe 'GET session_duration' do
    # a lot of the mechanics of this method are from Google Analytics
    # and Legato. It's really hard to test all the pieces of it,
    # so I'm just stubbing enough of the external models so that we can 
    # get through the method and have the request succeed
    before do
      Timecop.freeze
      allow_any_instance_of(DashboardController).to receive(:service_account_user).
        and_return(double('LegatoUser', profiles: [1,2,3]))
      allow(GaSession).to receive(:results).
        and_return(double('GaResults', dimensions: [], each: nil))
    end
    after { Timecop.return }
    let(:time_frame) { nil }
    subject!{ get :session_duration, time_frame: time_frame }

    it { expect(response.code).to eq '200' }

    context 'with time_frame "month"' do
      let(:time_frame) { 'month' }
      it 'should assign @from_date appropriately' do
        expect(assigns(:from_date)).to eq 1.month.ago
      end
    end

    context 'with time_frame "week"' do
      let(:time_frame) { 'week' }
      it 'should assign @from_date appropriately' do
        expect(assigns(:from_date)).to eq 1.week.ago
      end
    end

    context 'with time_frame "day"' do
      let(:time_frame) { 'day' }
      it 'should assign @from_date appropriately' do
        expect(assigns(:from_date)).to eq 1.day.ago
      end
    end
  end
end
