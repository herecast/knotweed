# frozen_string_literal: true
# == Schema Information
#
# Table name: contents
#
#  id                        :bigint(8)        not null, primary key
#  title                     :string(255)
#  subtitle                  :string(255)
#  authors                   :string(255)
#  raw_content               :text
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  pubdate                   :datetime
#  url                       :string(255)
#  origin                    :string(255)
#  page                      :string(255)
#  authoremail               :string(255)
#  organization_id           :bigint(8)
#  timestamp                 :datetime
#  parent_id                 :bigint(8)
#  has_event_calendar        :boolean          default(FALSE)
#  channelized_content_id    :bigint(8)
#  channel_type              :string(255)
#  channel_id                :bigint(8)
#  root_content_category_id  :bigint(8)
#  view_count                :bigint(8)        default(0)
#  comment_count             :bigint(8)        default(0)
#  commenter_count           :bigint(8)        default(0)
#  created_by_id             :bigint(8)
#  updated_by_id             :bigint(8)
#  banner_click_count        :bigint(8)        default(0)
#  similar_content_overrides :text
#  banner_ad_override        :bigint(8)
#  root_parent_id            :bigint(8)
#  deleted_at                :datetime
#  authors_is_created_by     :boolean          default(FALSE)
#  subscriber_mc_identifier  :string
#  biz_feed_public           :boolean
#  sunset_date               :datetime
#  promote_radius            :integer
#  ad_promotion_type         :string
#  ad_campaign_start         :date
#  ad_campaign_end           :date
#  ad_max_impressions        :integer
#  short_link                :string
#  ad_invoiced_amount        :float
#  first_served_at           :datetime
#  removed                   :boolean          default(FALSE)
#  ad_invoice_paid           :boolean          default(FALSE)
#  ad_commission_amount      :float
#  ad_commission_paid        :boolean          default(FALSE)
#  ad_services_amount        :float
#  ad_services_paid          :boolean          default(FALSE)
#  ad_sales_agent            :integer
#  ad_promoter               :integer
#  latest_activity           :datetime
#  has_future_event_instance :boolean
#  alternate_title           :string
#  alternate_organization_id :integer
#  alternate_authors         :string
#  alternate_text            :string
#  alternate_image_url       :string
#  location_id               :integer
#  mc_campaign_id            :string
#  ad_service_id             :string
#  content_category          :string
#
# Indexes
#
#  idx_16527_authors                                     (authors)
#  idx_16527_index_contents_on_authoremail               (authoremail)
#  idx_16527_index_contents_on_channel_id                (channel_id)
#  idx_16527_index_contents_on_channel_type              (channel_type)
#  idx_16527_index_contents_on_channelized_content_id    (channelized_content_id)
#  idx_16527_index_contents_on_created_by                (created_by_id)
#  idx_16527_index_contents_on_parent_id                 (parent_id)
#  idx_16527_index_contents_on_root_content_category_id  (root_content_category_id)
#  idx_16527_index_contents_on_root_parent_id            (root_parent_id)
#  idx_16527_pubdate                                     (pubdate)
#  idx_16527_source_id                                   (organization_id)
#  idx_16527_title                                       (title)
#  index_contents_on_ad_service_id                       (ad_service_id)
#  index_contents_on_content_category                    (content_category)
#  index_contents_on_location_id                         (location_id)
#
# Foreign Keys
#
#  fk_rails_...  (location_id => locations.id)
#

require 'spec_helper'

describe Content, type: :model do
  it { is_expected.to belong_to(:location) }
  it { is_expected.to have_db_column :promote_radius }
  it { is_expected.to have_db_column(:short_link).of_type(:string) }

  include_examples 'Auditable', Content

  describe 'validation' do
    context 'when ad_promotion_type = sponsored' do
      it 'ad_max_impressions must be populated' do
        content = FactoryGirl.build :content,
                                    ad_promotion_type: PromotionBanner::SPONSORED,
                                    ad_max_impressions: nil
        expect(content).not_to be_valid
      end
    end
  end

  describe '#should_index?' do
    context 'when content is soft deleted' do
      let(:content) { FactoryGirl.create :content, deleted_at: Date.yesterday }

      it 'returns false' do
        expect(content.should_index?).to be false
      end
    end

    context 'when pubdate is within past five years and before today' do
      let(:content) { FactoryGirl.create :content, pubdate: Date.yesterday }

      it 'returns true' do
        expect(content.should_index?).to be true
      end
    end
  end

  it { is_expected.to respond_to(:deleted_at) }

  describe 'find_root_parent' do
    it 'should return self for a content with no parent' do
      c = FactoryGirl.create(:content)
      expect(c.find_root_parent).to eq(c)
    end
    it 'should return the root parent for content' do
      c1 = FactoryGirl.create(:content)
      c2 = FactoryGirl.create(:content, organization: c1.organization, parent: c1)
      c3 = FactoryGirl.create(:content, organization: c1.organization, parent: c2)
      expect(c2.find_root_parent).to eq(c1)
      expect(c3.find_root_parent).to eq(c1)
    end
  end

  describe 'comments' do
    before do
      @content = FactoryGirl.create :content
      @comment1 = FactoryGirl.create :comment
      @comment1.content.update_attribute :parent_id, @content.id
    end

    it 'should return the content records of comments associated with it' do
      expect(@content.comments).to eq([@comment1.content])
    end
  end

  describe 'callbacks for denormalized attributes' do
    before do
      @parent = FactoryGirl.create :content
      @content = FactoryGirl.build :content, parent: @parent
    end

    subject { @content.save }

    describe 'set_root_parent_id' do
      it 'should set root_parent_id' do
        expect { subject }.to change { @content.root_parent_id }.to @parent.id
      end

      it 'should set root_parent_id appropriately if the parent is not the root' do
        parent2 = FactoryGirl.create :content
        @parent.update_attribute :parent_id, parent2.id
        expect { subject }.to change { @content.root_parent_id }.to parent2.id
      end

      it 'should set root_parent_id to self.id when no parent exists' do
        c = FactoryGirl.create :content
        expect(c.root_parent_id).to eq c.id
      end

      context 'for existing content' do
        it 'should update the root_parent_id if parent_id changes' do
          @content.save
          @content.parent = nil
          expect { @content.save }.to change { @content.root_parent_id }.to @content.id
        end
      end
    end
  end

  describe 'Content.search', elasticsearch: true do
    describe 'organization name' do
      before do
        @caster = FactoryGirl.create :caster, handle: 'handle', name: 'name'
        @content = FactoryGirl.create :content
      end

      it 'should index caster name' do
        search = Content.search(@content.caster.name)
        expect(search.results).to eq([@content])
      end

      it 'should index caster handle' do
        search = Content.search(@content.caster.handle)
        expect(search.results).to eq([@content])
      end
    end
  end

  describe 'increment_view_count!' do
    before do
      @published_content = FactoryGirl.create(:content, :located, :published)
      @unpublished_content = FactoryGirl.create(:content, :located, pubdate: nil)
    end

    it 'should increment the view count' do
      expect { @published_content.increment_view_count! }.to change { @published_content.view_count }.by 1
    end

    it 'should not increment the view count if not published' do
      expect { @unpublished_content.increment_view_count! }.not_to change { @unpublished_content.view_count }
    end

    context 'for a user with skip_analytics = true' do
      before do
        @user = FactoryGirl.create :user, skip_analytics: true
        User.current = @user
      end

      it 'should not increment the view count' do
        expect { @unpublished_content.increment_view_count! }.not_to change { @unpublished_content.view_count }
      end

      it 'should not increment if the root content is news' do
        @published_content.update_attributes(content_category: 'news')
        @published_content.save!
        expect { @published_content.increment_view_count! }.not_to change { @published_content.view_count }
      end

      it 'should increment view count for other channels' do
        @published_content.update_attributes(content_category: 'event')
        @published_content.save!
        expect { @published_content.increment_view_count! }.to change { @published_content.view_count }
      end
    end
  end

  describe 'similar_content', elasticsearch: true do
    let!(:content) { FactoryGirl.create :content }
    let(:sim_attributes) do
      {
        raw_content: content.sanitized_content,
        title: content.title,
        origin: Content::UGC_ORIGIN
      }
    end

    # similar_content comes back as raw ES data for the API,
    # so map to IDs for testing
    subject { content.similar_content(4).map(&:id) }

    describe 'with normal content with identical content fields' do
      let!(:sim_content) { FactoryGirl.create :content, sim_attributes }

      it 'should respond with that content' do
        expect(subject).to match_array([sim_content.id])
      end
    end

    describe 'with similar content that is non-UGC' do
      let!(:sim_content) { FactoryGirl.create :content, sim_attributes.merge(origin: 'Not one bit UGC') }

      it 'should not respond with that content' do
        expect(subject).to_not include(sim_content.id)
      end
    end

    describe 'with similar content with no pubdate' do
      let!(:sim_draft) { FactoryGirl.create :content, sim_attributes.merge(pubdate: nil) }

      it 'should not respond with that content' do
        expect(subject).to_not include(sim_draft.id)
      end
    end

    describe 'with similar content with a future pubdate' do
      let!(:sim_draft) { FactoryGirl.create :content, sim_attributes.merge(pubdate: 1.week.from_now) }

      it 'should not respond with that content' do
        expect(subject).to_not include(sim_draft.id)
      end
    end

    describe 'with similar event' do
      let(:sim_content) { FactoryGirl.create :content, sim_attributes }
      let!(:sim_event) do
        FactoryGirl.create :event,
                           start_date: start_date,
                           content: sim_content
      end

      before { ReindexEventsWithFutureInstances.perform_now }

      context 'with future instances' do
        let(:start_date) { 1.week.from_now }

        it 'should respond with that event' do
          expect(subject).to include(sim_content.id)
        end
      end

      context 'with no future instances' do
        let(:start_date) { 1.week.ago }

        it 'should not respond with that event' do
          expect(subject).to_not include(sim_content.id)
        end
      end
    end
  end

  describe 'title=t' do
    it 'should automatically strip the title attribute' do
      c = FactoryGirl.create :content, title: '   This has Whitespace at Beginning And End  '
      expect(c.title).to eq c.title.strip
    end
  end

  describe '#sanitized_title' do
    context 'when no title present' do
      it 'returns nil' do
        content = FactoryGirl.create :content, title: nil
        expect(content.sanitized_title).to be_nil
      end
    end

    context 'when title present' do
      it 'returns title' do
        content = FactoryGirl.create :content, title: 'In a galaxy...'
        expect(content.sanitized_title).to eq content.title
      end
    end

    context 'when title is only listserv name' do
      it "returns 'Post by...' title" do
        user = FactoryGirl.create :user, name: 'Han Solo'
        content = FactoryGirl.create :content, title: '[Hoth]',
                                               created_by: user, content_category: 'talk_of_the_town'
        expect(content.sanitized_title).to include 'Han Solo'
      end
    end
  end

  describe 'sanitized_content=' do
    it 'sets raw_content' do
      content = 'Test Content'
      expect(subject).to receive(:raw_content=).with(content)
      subject.sanitized_content = content
    end
  end

  describe '#sanitized_content' do
    subject { @content.sanitized_content }

    context 'for UGC content' do
      before { @content = FactoryGirl.create :content, origin: Content::UGC_ORIGIN }

      it 'should use the ugc_sanitized_content method' do
        expect(@content).to receive(:ugc_sanitized_content)
        subject
      end

      it 'should match output of ugc_sanitized_content' do
        expect(subject).to eq @content.ugc_sanitized_content
      end

      it 'does not strip style attributes from image tags' do
        img_content = '<img style="float: left; padding: 9px; width: 50%">'
        @content.raw_content = img_content
        expect(subject.html_safe).to eql img_content.html_safe
      end
    end
  end

  describe '#author_name' do
    before do
      # default cat is news which changes this behavior, so specifying another category
      @content = FactoryGirl.create :content, content_category: 'talk_of_the_town',
        authors: Faker::Name.name
      @content.update_column :created_by_id, nil
    end
    let(:user) { FactoryGirl.create :user }

    subject { @content.author_name }

    context 'with `created_by` populated' do
      before { @content.update_attribute :created_by, user }

      it 'should return the associated user\'s name' do
        expect(subject).to eq user.name
      end
    end

    context 'without `created_by` populated' do
      it 'should return the `authors` column' do
        expect(subject).to eq @content.authors
      end
    end

    context 'for news UGC content' do
      before do
        @content.origin = Content::UGC_ORIGIN
        @content.content_category = 'news'
      end

      context 'with authors populated' do
        it { should eql @content.authors }
      end

      context 'without authors populated' do
        before do
          @content.created_by = user
          @content.authors = nil
        end
        it { should be_blank }

        context 'with authors_is_created_by true' do
          before { @content.authors_is_created_by = true }

          it { should eq user.name }
        end
      end
    end
  end

  describe '#is_news_ugc?' do
    subject { content.is_news_ugc? }
    describe 'for news UGC' do
      let (:content) { FactoryGirl.build :content, :news, origin: Content::UGC_ORIGIN }

      it { should be true }
    end

    describe 'for other content' do
      let(:content) { FactoryGirl.build :content, content_category: 'event' }
      it { should be false }
    end
  end

  describe '#current_daily_report' do
    before do
      @news = FactoryGirl.create :content, :news
    end

    subject { @news.current_daily_report }

    context 'when no daily report present' do
      before do
        @content_report = FactoryGirl.create :content_report, report_date: Date.yesterday
        @news.content_reports << @content_report
      end

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when daily report present' do
      before do
        @content_report = FactoryGirl.create :content_report, report_date: Date.current
        @news.content_reports << @content_report
      end

      it 'returns current report' do
        expect(subject).to eq @content_report
      end
    end
  end

  describe '#find_or_create_daily_report' do
    before do
      @news = FactoryGirl.create :content, :news
    end

    subject { @news.find_or_create_daily_report }

    context 'when no report present' do
      it 'creates daily report' do
        expect { subject }.to change {
          @news.reload.content_reports.count
        }.by 1
      end
    end

    context 'when current report available' do
      before do
        @content_report = FactoryGirl.create :content_report, report_date: Date.current
        @news.content_reports << @content_report
      end

      it 'returns current report' do
        expect(subject).to eq @content_report
      end
    end
  end

  describe '#latest_activity' do
    before do
      Timecop.freeze
    end

    after do
      Timecop.return
    end

    subject { FactoryGirl.create :content }

    it 'is initially the pubdate time' do
      subject
      expect(subject.latest_activity).to eql subject.pubdate
    end

    context 'comment posted' do
      let!(:comment) do
        FactoryGirl.create :content, :comment, parent: subject
      end

      it 'is the pubdate of the comment' do
        subject
        comment
        expect(subject.latest_activity).to eql comment.pubdate
      end
    end

    context 'when publisher schedules news post' do
      let(:scheduled_pubdate) { 3.days.from_now }

      subject { FactoryGirl.create :content, :news, pubdate: scheduled_pubdate }

      it 'latest_activity is scheduled time' do
        expect(subject.latest_activity).to eql scheduled_pubdate
      end
    end

    context 'when draft News gets a pubdate' do
      before do
        @draft_news = FactoryGirl.create :content, :news, pubdate: nil
      end

      let(:new_pubdate) { 2.days.from_now }

      subject { @draft_news.update_attribute(:pubdate, new_pubdate) }

      it 'updates latest_activity to pubdate' do
        expect { subject }.to change {
          @draft_news.latest_activity
        }.to new_pubdate
      end
    end
  end

  describe "creating a comment, reindexes it's root parent", elasticsearch: true do
    let!(:root_parent) { FactoryGirl.create :content }

    it 'does not reindex when root_parent is self' do
      self_content = FactoryGirl.build :content
      expect(self_content).to receive(:reindex).exactly(1).times
      self_content.save!
    end

    it 'child' do
      expect(root_parent).to receive(:reindex)
      FactoryGirl.create :content, :comment, parent: root_parent
    end

    it 'grandchild' do
      child = FactoryGirl.create :content, :comment, parent: root_parent

      grandchild = FactoryGirl.build :content, :comment, parent: child
      # to ensure same instance as in test stub
      allow(grandchild).to receive(:root_parent).and_return(root_parent)
      expect(root_parent).to receive(:reindex)

      grandchild.save!
    end
  end

  describe '#built_view_count' do
    before do
      @view_count = 47
    end

    subject { @content.built_view_count }

    context 'when content_category is campaign' do
      before do
        @content = FactoryGirl.create :content, :campaign
        promotable = FactoryGirl.create :promotion_banner,
                                        impression_count: @view_count
        promotion = FactoryGirl.create :promotion,
                                       content_id: @content.id,
                                       promotable_id: promotable.id,
                                       promotable_type: 'PromotionBanner'
      end

      it 'returns promotable impression count' do
        expect(subject).to eq @view_count
      end
    end

    context 'when content has a parent' do
      before do
        parent = FactoryGirl.create :content,
                                    view_count: @view_count
        @content = FactoryGirl.create :content,
                                      parent_id: parent.id
      end

      it 'returns parent view count' do
        expect(subject).to eq @view_count
      end
    end

    context 'when content has no parent' do
      before do
        @content = FactoryGirl.create :content,
                                      view_count: @view_count
      end

      it 'returns content view_count' do
        expect(subject).to eq @view_count
      end
    end
  end
end
