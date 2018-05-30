require 'spec_helper'

describe IssuesController, type: :controller do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
  end

  describe '#new' do
    it 'assigns @issue' do
      get :new
      expect(assigns(:issue)).to be_a Issue
    end

    context 'When given organization_id' do
      let(:organization){ FactoryGirl.create :organization }

      it 'preloads the organization' do
        get :new, organization_id: organization.id
        expect(assigns(:issue).organization).to eql organization
      end
    end
  end

  describe '#create' do
    let(:attrs) {
      FactoryGirl.attributes_for(:issue).merge(
        organization_id: FactoryGirl.create(:organization).id)
    }

    it 'creates a record' do
      expect { xhr :post, :create, issue: attrs, format: :js }.to change{ Issue.count }.by(1)
    end
  end

  context 'Given an existing issue' do
    let!(:record) { FactoryGirl.create :issue }
    before do
      allow(Issue).to receive(:find).and_return(record)
    end
    describe '#edit' do
      it 'renders issues/_form partial' do
        xhr :get, :edit, id: record.id, format: :js
        expect(response).to render_template('issues/_form')
      end
    end

    describe '#update' do
      it 'updates record' do
        xhr :put, :update, id: record.id, issue: { issue_edition: "Test Edition" }, format: :js
        expect(record.reload.issue_edition).to eql "Test Edition"
      end
    end

    describe '#show' do
      it 'returns issue as json' do
        xhr :get, :show, id: record.id, format: :js
        record_json = {issue: record}.to_json
        expect(response.body).to eql record_json
      end
    end

    describe '#destroy' do
      it 'destroys record' do
        expect(record).to receive(:destroy)
        xhr :delete, :destroy, id: record.id, format: :js
      end
    end
  end
end
