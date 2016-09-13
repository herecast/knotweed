require 'rails_helper'

RSpec.describe ReceivedEmailsController, type: :controller do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
  end

  describe "GET #index" do
    before do
      created_at = 1.hour.ago
      3.times do |i|
        created_at = created_at + 1.minute
        FactoryGirl.create :received_email, created_at: created_at, 
          file_uri: "/tmp/fake.email#{i}.eml"
      end
    end
    it "assigns paginated received_emails as @received_emails" do
      get :index, {page: 1, per_page: 2}

      expect(assigns(:received_emails).count).to eql 2
    end

    it 'orders by created_at DESC' do
      get :index

      expect(assigns(:received_emails).first).to eql ReceivedEmail.last
    end
  end

  describe "GET #show" do
    it "assigns the requested received_email as @received_email" do
      received_email = FactoryGirl.create :received_email
      get :show, {:id => received_email.to_param}
      expect(assigns(:received_email)).to eq(received_email)
    end
  end

end
