require 'spec_helper'

describe IssuesController, type: :controller do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
  end

  describe '#select_options' do
    let!(:issues) { FactoryGirl.create_list :issue, 3 }

    it 'assigns @issues to mapped select options' do
      get :select_options
      issue_list = assigns(:issues)
      issues.each do |issue|
        expect(issue_list).to include([issue.issue_edition, issue.id])
      end
    end

    context 'scoped to organization' do
      let(:organization){ FactoryGirl.create :organization }
      let(:scoped_issues){ issues.slice(0,2) }
      let(:non_org_issue){ issues.last }
      before do
        scoped_issues.each{|i| i.update_attribute(:organization, organization)}
        get :select_options, organization_id: organization.id
      end

      subject { assigns(:issues) }

      it 'returns only the organization issues' do
        scoped_issues.each do |i|
          expect(subject).to include([i.issue_edition,i.id])
        end

        expect(subject).to_not include([non_org_issue.issue_edition,non_org_issue.id])
      end
    end
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
      expect { post :create, issue: attrs }.to change{ Issue.count }.by(1)
    end
  end

  context 'Given an existing issue' do
    let!(:record) { FactoryGirl.create :issue }
    before do
      allow(Issue).to receive(:find).and_return(record)
    end
    describe '#edit' do
      it 'renders issues/_form partial' do
        get :edit, id: record.id, format: 'js'
        expect(response).to render_template('issues/_form')
      end
    end

    describe '#update' do
      it 'updates record' do
        put :update, id: record.id, issue: { issue_edition: "Test Edition" }
        expect(record.reload.issue_edition).to eql "Test Edition"
      end
    end

    describe '#show' do
      it 'returns issue as json' do
        get :show, id: record.id, format: :js
        record_json = {issue: record}.to_json
        expect(response.body).to eql record_json
      end
    end

    describe '#destroy' do
      it 'destroys record' do
        expect(record).to receive(:destroy)
        delete :destroy, id: record.id
      end
    end
  end
end