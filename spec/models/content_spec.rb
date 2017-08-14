# == Schema Information
#
# Table name: contents
#
#  id                        :integer          not null, primary key
#  title                     :string(255)
#  subtitle                  :string(255)
#  authors                   :string(255)
#  raw_content               :text
#  issue_id                  :integer
#  import_location_id        :integer
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  copyright                 :string(255)
#  guid                      :string(255)
#  pubdate                   :datetime
#  source_category           :string(255)
#  topics                    :string(255)
#  url                       :string(255)
#  origin                    :string(255)
#  language                  :string(255)
#  page                      :string(255)
#  authoremail               :string(255)
#  organization_id           :integer
#  quarantine                :boolean          default(FALSE)
#  doctype                   :string(255)
#  timestamp                 :datetime
#  contentsource             :string(255)
#  import_record_id          :integer
#  source_content_id         :string(255)
#  parent_id                 :integer
#  content_category_id       :integer
#  category_reviewed         :boolean          default(FALSE)
#  has_event_calendar        :boolean          default(FALSE)
#  channelized_content_id    :integer
#  published                 :boolean          default(FALSE)
#  channel_type              :string(255)
#  channel_id                :integer
#  root_content_category_id  :integer
#  view_count                :integer          default(0)
#  comment_count             :integer          default(0)
#  commenter_count           :integer          default(0)
#  created_by                :integer
#  updated_by                :integer
#  banner_click_count        :integer          default(0)
#  similar_content_overrides :text
#  banner_ad_override        :integer
#  root_parent_id            :integer
#  deleted_at                :datetime
#  authors_is_created_by     :boolean          default(FALSE)
#  subscriber_mc_identifier  :string
#  biz_feed_public           :boolean
#  sunset_date               :datetime
#

require 'spec_helper'

describe Content, :type => :model do

  it { is_expected.to have_many 'content_locations' }
  it { is_expected.to have_many 'locations' }
  it { is_expected.to have_db_column :promote_radius }

  before { allow_any_instance_of(Promotion).to receive(:update_active_promotions).and_return(true) }

  include_examples 'Auditable', Content

  describe '#update_category_from_annotations' do
    let (:new_category) { 'RandomCategory' }

    context 'Given CATEGORY' do
      let(:annotations) do
        { 'document-parts' =>
          { 'feature-set' => [
            { 'name' =>
              { 'name' => 'CATEGORY' },
              'value' =>
                { 'value' => new_category }
            }]
          }
        }
      end

      it 'should update content_category' do
        subject.update_category_from_annotations(annotations)
        expect(subject.content_category.name).to eq new_category
      end
    end

    context 'Given CATEGORIES without CATEGORY' do
      let(:annotations) do
        { 'document-parts' =>
          { 'feature-set' => [
            { 'name' =>
              { 'name' => 'CATEGORIES' },
              'value' =>
                { 'value' => new_category }
            }]
          }
        }
      end

      it 'should update content_category' do
        subject.update_category_from_annotations(annotations)
        expect(subject.content_category.name).to eq new_category
      end
    end

    context 'Given CATEGORIES with CATEGORY' do
      let (:other_category) { 'MarksManQuail' }
      let(:annotations) do
        { 'document-parts' =>
          { 'feature-set' => [
            { 'name' =>
              { 'name' => 'CATEGORIES' },
              'value' =>
                { 'value' => new_category }
            },

            { 'name' =>
              { 'name' => 'CATEGORY' },
              'value' =>
                { 'value' => other_category }
            }]
          }
        }
      end

      it 'CATEGORY should win over CATEGORIES' do
        subject.update_category_from_annotations(annotations)
        expect(subject.content_category.name).to eq other_category
      end
    end
  end

  describe "#should_index?" do
    context "when content is soft deleted" do
      let(:content) { FactoryGirl.create :content, deleted_at: Date.yesterday }

      it "returns false" do
        expect(content.should_index?).to be false
      end
    end

    context "when pubdate is within past five years and before today" do
      let(:content) { FactoryGirl.create :content, pubdate: Date.yesterday }

      it "returns true" do
        expect(content.should_index?).to be true
      end
    end
   end

  describe '#published?' do
    context 'Given a repo' do
      let(:repo) { FactoryGirl.create :repository }

      context 'When has repo' do
        before do
          subject.repositories << repo
        end

        it 'is true' do
          expect(subject.published?(repo)).to be_truthy
        end
      end

      context 'When does not have repo' do
        before do
          subject.repositories = []
        end

        it 'is false' do
          expect(subject.published?(repo)).to be_falsey
        end
      end
    end

    context 'When no repositories' do
      before do
        subject.repositories = []
      end

      it 'is false' do
        expect(subject.published?).to be_falsey
      end
    end

    context 'When in repositories' do
      before do
        subject.repositories << FactoryGirl.create(:repository)
      end

      it 'is false' do
        expect(subject.published?).to be_truthy
      end
    end
  end

  describe '#location' do
    context 'when #import_location nil' do
      before do
        allow(subject).to receive(:import_location).and_return(nil)
      end

      it 'is nil' do
        expect(subject.location).to be_nil
      end
    end

    context 'when #import_location exists' do
      before do
        subject.import_location = ImportLocation.new(city: "New York")
      end

      context 'when #import_location is in review status' do
        before do
          subject.import_location.status = ImportLocation::STATUS_REVIEW
        end

        it 'is nil' do
          expect(subject.location).to be_nil
        end
      end

      context 'when #import_location is in good status' do
        before do
          subject.import_location.status = ImportLocation::STATUS_GOOD
        end

        it 'is #import_location.city' do
          expect(subject.location).to eql subject.import_location.city
        end
      end
    end
  end

  describe "#base_locations" do
    let(:content) { FactoryGirl.create :content }
    let(:non_base) { FactoryGirl.create_list :location, 3 }
    let(:base) { FactoryGirl.create_list :location, 3 }

    before do
      non_base.each do |location|
        ContentLocation.create(
          content: content,
          location: location
        )
      end

      base.each do |location|
        ContentLocation.create(
          content: content,
          location: location,
          location_type: 'base'
        )
      end
    end

    it 'returns locations specified as "base"' do
      expect(content.base_locations).to include(*base)
      expect(content.base_locations).to_not include(*non_base)
    end
  end

  describe "#about_locations" do
    let(:content) { FactoryGirl.create :content }
    let(:non_about) { FactoryGirl.create_list :location, 3 }
    let(:about) { FactoryGirl.create_list :location, 3 }

    before do
      non_about.each do |location|
        ContentLocation.create(
          content: content,
          location: location
        )
      end

      about.each do |location|
        ContentLocation.create(
          content: content,
          location: location,
          location_type: 'about'
        )
      end
    end

    it 'returns locations specified as "about"' do
      expect(content.about_locations).to include(*about)
      expect(content.about_locations).to_not include(*non_about)
    end
  end

  it { is_expected.to respond_to(:deleted_at) }

  # for ease of querying, our polymorphic channel relationship
  # is redundantly specified using the content_id attribute
  # from each channel submodel. Rails doesn't provide an easy way to
  # ensure the redundant field is saved, or vice versa,
  # so we add a callback on each model
  describe "redundant channel relationship" do
    before do
      @content = FactoryGirl.create :content
      @event = FactoryGirl.create :event
      @event2 = FactoryGirl.create :event
    end
  end

  describe "find_root_parent" do
    it "should return self for a content with no parent" do
      c = FactoryGirl.create(:content)
      expect(c.find_root_parent).to eq(c)
    end
    it "should return the root parent for content" do
      c1 = FactoryGirl.create(:content)
      c2 = FactoryGirl.create(:content, organization: c1.organization, parent: c1)
      c3 = FactoryGirl.create(:content, organization: c1.organization, parent: c2)
      expect(c2.find_root_parent).to eq(c1)
      expect(c3.find_root_parent).to eq(c1)
    end
  end

  describe "get_downstream_thread" do
    it "should return nil for contents without children" do
      c = FactoryGirl.create(:content)
      expect(c.get_downstream_thread).to eq(nil)
    end

    it "should return a hash representing the full thread below the content" do
      c1 = FactoryGirl.create(:content)
      c2 = FactoryGirl.create(:content, organization: c1.organization, parent: c1)
      c3 = FactoryGirl.create(:content, organization: c1.organization, parent: c1)
      c4 = FactoryGirl.create(:content, organization: c1.organization, parent: c3)
      expect(c1.get_downstream_thread).to eq({
        c2.id => nil, c3.id => {
          c4.id => nil
        }
      })
    end
  end

  describe "mark_quarantined" do
    before do
      @content = FactoryGirl.create(:content)
    end

    it "should leave valid content unquarantined" do
      expect(@content.quarantine).to eq(false)
    end

    it "should mark it quarantined if sanitized_content is empty" do
      @content.raw_content = "<br/>"
      @content.save
      @content.reload
      expect(@content.quarantine).to eq(true)
    end

  end

  describe "mark_published association callback" do
    before do
      @prod_repo = FactoryGirl.create(:repository)
      stub_const("Repository::PRODUCTION_REPOSITORY_ID", @prod_repo.id)
      @non_prod_repo = FactoryGirl.create(:repository)
      @content = FactoryGirl.create(:content)
    end

    it "should not mark content published when added to a non-production repository" do
      @content.repositories << @non_prod_repo
      @content.reload
      expect(@content.published).to eq(false)
    end

    it "should mark content published when added to prod repo" do
      @content.repositories << @prod_repo
      @content.reload
      expect(@content.published).to eq(true)
    end

    it "sends notifications for news published to the prod repo" do
      @content = FactoryGirl.create(:content, :news)
      expect(@content.send(:outside_subscriber_notification_blast_radius?)).to eq false
      expect(NotifySubscribersJob).to receive(:perform_later)
      @content.repositories << @prod_repo
    end

    context "organization is outside of blast radius" do
      it "does not send notification to subscribers" do
        org = FactoryGirl.create(:organization, name: Content::ORGANIZATIONS_NOT_FOR_AUTOMATIC_SUBSCRIBER_ALERTS.first)
        @content = FactoryGirl.create(:content, :news, organization: org)
        expect(@content.send(:outside_subscriber_notification_blast_radius?)).to eq true
        expect(NotifySubscribersJob).to_not receive(:perform_later)
        @content.repositories << @prod_repo
      end
    end
  end

  context "a published news item" do
    before do
      @prod_repo = FactoryGirl.create(:repository)
      stub_const("Repository::PRODUCTION_REPOSITORY_ID", @prod_repo.id)
      @content = FactoryGirl.create(:content, :news)
      expect(@content.send(:outside_subscriber_notification_blast_radius?)).to eq false
      @content.repositories << @prod_repo
      expect(@content.reload.published).to be_truthy
    end

    describe "changing the title" do
      it "updates the subscriber notification" do
        expect(NotifySubscribersJob).to receive(:perform_later)
        @content.update(title: "#{@content.title}-new!")
      end
    end
  end

  describe "publish_content" do
    before do
      @content = FactoryGirl.create(:content)
    end

    it "should return sanitized_content if it has anything in it" do
      expect(@content.publish_content(true)).to eq(@content.sanitized_content)
    end

    it "should strip tags from result if include_tags parameter is false" do
      @content.raw_content = "<p>Hello</p>"
      expect(@content.publish_content(false)).to eq("Hello")
    end

    it "should not strip tags from result if include_tags parameter is true" do
      @content.raw_content = "<p>Hello</p>"
      expect(@content.publish_content(true).include?(@content.raw_content)).to eq(true)
    end
  end

  describe "create from import job" do
    before do
      # base_data is not enough to pass quarantine
      # need to add pubdate, organization to validate
      @base_data = {
        "title" => "This is a Title",
        "subtitle" => "Subtitle",
        "page" => "a3",
        "source_content_id" => "1234567"
      }
      #stub some images
      google_logo_stub
      google_logo2_stub
      google_logo3_stub
      google_logo4_stub
      google_logo5_stub
    end

    it "should create a new content with basic data passed by hash" do
      expect(Content.count).to eq(0)
      content = Content.create_from_import_job(@base_data)
      expect(Content.count).to eq(1)
    end

    it "should mark non-valid corpus entries as quarantined" do
      content = Content.create_from_import_job(@base_data)
      expect(content.quarantine).to eq(true)
    end

    it "should leave valid corpus entries as unquarantined" do
      p = FactoryGirl.create(:organization)
      extra_data = @base_data.merge({
        "pubdate" => Time.current,
        "content" => "hello",
        "organization_id" => p.id
      })
      content = Content.create_from_import_job(extra_data)
      expect(content.quarantine).to eq(false)
    end

    it "should correctly identify parent based on in_reply_to" do
      co = FactoryGirl.create(:content, guid: "this-is-a-guid")
      co.published=true
      co.repositories << FactoryGirl.create(:repository)
      co.save
      # the above 2 lines are necessary for the item to be considered published
      extra_data = @base_data.merge({
        "pubdate" => Time.current,
        "content" => "hello",
        "organization_id" => co.organization.id,
        "in_reply_to" => co.guid
      })
      c2 = Content.create_from_import_job(extra_data)
      expect(c2.parent).to eq(co)
    end

    context "when parent content is not published" do
      before do
        @parent = FactoryGirl.create :content, guid: "loko-joko", published: false, repositories: []
        extra_data = @base_data.merge({
          "pubdate" => Time.current,
          "content" => "hello",
          "organization_id" => @parent.organization.id,
          "in_reply_to" => @parent.guid
        })
        @child = Content.create_from_import_job extra_data
      end
      it "should refuse to set parent" do
        expect(@child.parent).to be_nil
      end
    end

    context "when parent is quarantined" do
      before do
        @parent = FactoryGirl.create :content, guid: "rat-race", title: nil
        extra_data = @base_data.merge({
          "pubdate" => Time.current,
          "content" => "hello",
          "organization_id" => @parent.organization.id,
          "in_reply_to" => @parent.guid
        })
        @child = Content.create_from_import_job extra_data
      end

      it "should refuse to set the parent" do
        expect(@parent.quarantine?).to be_truthy
        expect(@child.parent).to be_nil
      end
    end

    it "should overwrite any existing content with the same organization and source_content_id" do
      p = FactoryGirl.create(:organization)
      @base_data["organization_id"] = p.id
      content_orig = Content.create_from_import_job(@base_data)
      orig_id = content_orig.id
      @new_data = {
        "title" => "Different Title",
        "source_content_id" => @base_data["source_content_id"],
        "organization_id" => @base_data["organization_id"]
      }
      new_content = Content.create_from_import_job(@new_data)
      expect(new_content.id).to eq(orig_id)
      expect(Content.count).to eq(1)
      db_content = Content.all.first
      expect(db_content.title).to eq("Different Title")
    end



    it "should overwrite any existing content with the same guid" do
      p = FactoryGirl.create(:organization)
      @base_data["organization_id"] = p.id
      c1 = Content.create_from_import_job(@base_data)
      orig_id = c1.id
      @new_data = {
        "title" => "Different Title",
        "organization_id" => @base_data["organization_id"],
        "guid" => c1.guid
      }
      c2 = Content.create_from_import_job(@new_data)
      expect(Content.count).to eq(1)
      expect(Content.first.id).to eq(orig_id)
    end

    context 'when we import different content records with same title,email, on same date(not datetime), where root_content_category != news AND channel_type is null' do
      before do
        FactoryGirl.create :content_category, name: 'news'
        org = FactoryGirl.create :organization
        @orig_data = {title: 'The Book of Worms',
                      guid: '35q5j35jq3j53qj5kjq5',
                      location: Faker::Address.street_name,
                      organization_id: org.id,
                      authoremail: Faker::Internet.email,
                      pubdate: DateTime.parse("1/2/2015 08:15:00"),
                      source_content_id: '3538538',
                      source_category: 'Category',
                      content_category: 'Category 422',
                      content_locations: [FactoryGirl.create(:location).city] }
        @c1 = Content.create_from_import_job(@orig_data)
        @new_data = @orig_data.merge({source_content_id: @orig_data[:source_content_id] + '7',
                                    location: @orig_data[:location] + ' different',
                                    content_locations: [FactoryGirl.create(:location).city],
                                    guid: '53939itqjg3q0353jt',
                                    pubdate: DateTime.parse("1/2/2015 11:15:00")})
        @c2 = Content.create_from_import_job(@new_data)
      end

      it 'should update the existing content, appending a new location to it' do
        expect(Content.count).to eq 1
        expect(@c1.id).to eq @c2.id
        expect(@c1.locations.count).to eq 2
        expect(@c1.locations.include?(@c2.locations.first)).to be_truthy
      end

      context 'when title starts with a listserve name' do
        before do
          @orig_data[:title] = '[Norwich ListServ] An amazing tale of muisical Genius'
          @new_data[:title] = '[Bedford Queue] An amazing tale of muisical Genius'
          @c3 = Content.create_from_import_job(@orig_data)
          @c4 = Content.create_from_import_job(@new_data)
        end

        it 'should update the existing content, appending a new location to it' do
          expect(@c3.id).to eq @c4.id
          expect(@c3.locations.count).to eq 2
          expect(@c3.locations.include?(@c4.locations.first)).to be_truthy
        end
      end

      context 'if the first content has a listserv name and the next similar content does not, ' do
        before do
          @orig_data[:title] = '[Seagate] A gentle awakening'
          @new_data[:title] = 'A gentle awakening'
          @c5 = Content.create_from_import_job @orig_data
          @c6 = Content.create_from_import_job @new_data
        end

        it 'we should update the existing content, appending a new location to it' do
          expect(@c5.id).to eq @c6.id
          expect(@c5.locations.count).to eq 2
          expect(@c5.locations.include?(@c6.locations.first)).to be_truthy
        end
      end

      context 'when post is in response to a reply to an original post by the same author' do
        before do
          @orig_data[:title] = '[Norwich ListServ] Town Audit'
          @new_data[:title] = 'Re: [Norwich ListServ] Town Audit'
          @c7 = Content.create_from_import_job(@orig_data)
          @c8 = Content.create_from_import_job(@new_data)
        end

        it 'should not update the existing content' do
          expect(@c7.id).not_to eq @c8.id
          expect(@c7.locations.count).to eq 2
          expect(@c8.locations.count).to eq 1
        end
      end

    end

    it "should overwrite any content but retain new category if category field is populated " do
      p = FactoryGirl.create(:organization)
      @base_data["organization_id"] = p.id
      c1 = Content.create_from_import_job(@base_data)
      c1.update_attribute :category, "Test Category"
      orig_id = c1.id
      @new_data = {
        "title" => "Different Title",
        "organization_id" => @base_data["organization_id"],
        "guid" => c1.guid
      }
      c2 = Content.create_from_import_job(@new_data)
      expect(Content.count).to eq(1)
      expect(Content.first.id).to eq(orig_id)
      expect(Content.first.category).to eq("Test Category")
    end

    it "should not overwrite any fields not in the REIMPORT_FEATURES whitelist" do
      p = FactoryGirl.create(:organization)
      @base_data["organization_id"] = p.id
      c1 = Content.create_from_import_job(@base_data)
      c1.update_attribute :copyright, "ropycight" #an attribute that is not whitelisted for reimport
      @new_data = {
        "title" => "New Title",
        "organization_id" => @base_data["organization_id"],
        "guid" => c1.guid,
        "copyright" => "different" # an attribute that is not whitelisted
      }
      Content.create_from_import_job(@new_data)
      c1.reload
      expect(c1.title).to eq(@new_data["title"])
      expect(c1.copyright).to eq("ropycight") # original
    end

    # check source logic
    it "should create organization if source is provided and it doesn't match existing organizations" do
      @base_data["source"] = "Test Organization"
      content = Content.create_from_import_job(@base_data)
      expect(content.organization.name).to eq("Test Organization")
    end
    it "should match an existing organization if source matches organization name and source_field not provided" do
      org = FactoryGirl.create(:organization)
      @base_data["source"] = org.name
      content = Content.create_from_import_job(@base_data)
      expect(content.organization).to eq(org)
    end

    # check location logic
    it "should create a new location if none is found" do
      @base_data["location"] = "Test Location"
      content = Content.create_from_import_job(@base_data)
      expect(content.import_location.city).to eq("Test Location")
    end
    it "should match existing locations by city" do
      loc = FactoryGirl.create(:import_location)
      @base_data["location"] = loc.city
      content = Content.create_from_import_job(@base_data)
      expect(content.import_location.city).to eq(loc.city)
    end

    # check issue/edition logic
    it "should create a new edition if none is found" do
      @base_data["edition"] = "Holiday Edition"
      content = Content.create_from_import_job(@base_data)
      expect(content.issue.issue_edition).to eq("Holiday Edition")
    end
    it "should assign the appropriate data to the newly created issue" do
      @base_data["edition"] = "Holiday Edition"
      @base_data["source"] = "Test org"
      content = Content.create_from_import_job(@base_data)
      expect(content.issue.issue_edition).to eq("Holiday Edition")
      expect(content.issue.publication_date).to eq(content.pubdate)
      expect(content.issue.organization).to eq(content.organization)
    end
    it "should match existing issues by organization and name" do
      pubdate = Time.current
      issue_1 = FactoryGirl.create(:issue, publication_date: pubdate) # matching pub
      issue_2 = FactoryGirl.create(:issue, issue_edition: issue_1.issue_edition) #matching name, different pub
      @base_data["edition"] = issue_1.issue_edition
      @base_data["source"] = issue_1.organization.name
      @base_data["pubdate"] = pubdate

      content = Content.create_from_import_job(@base_data)
      expect(content.issue).to eq(issue_1)
    end

    it "should set the import_record_id of content if provided" do
      record = FactoryGirl.create(:import_record)
      content = Content.create_from_import_job(@base_data, record.import_job)
      expect(content.import_record).to eq(record)
    end

    it "should create an image record and copy the file to our CDN if 'image' is provided" do
      @base_data["image"] = "https://www.google.com/images/srpr/logo11w.png"
      c = Content.create_from_import_job(@base_data)
      expect(c.images.count).to eq(1)
      image = c.images.first
      expect(image.image.url.present?).to eq(true)
      expect(image.source_url).to eq("https://www.google.com/images/srpr/logo11w.png")
    end

    describe 'should handle created_by and updated_by correctly' do

      it 'should set created_by and updated_by correctly for new imported content' do
        # @user created in auditable_shared_examples.rb included using include_examples 'Auditable', Content
        @base_data['user_id'] = @user.id
        c = Content.create_from_import_job(@base_data)
        expect(c.created_by).to eq(@user)
        expect(c.updated_by).to eq(@user)
      end

    end
    # check primary image handling
    describe 'should handle primary images with NO images present' do
      before do
        @c = Content.create_from_import_job(@base_data)
      end

      it 'should not have a primary image' do
        expect(@c.primary_image).to be_nil
      end
    end

    describe 'should handle primary image correctly with images present' do
      before do
        @base_data['images'] = [{'image' => 'https://www.google.com/images/srpr/logo11w.png'},
                                {'image' => 'https://www.google.com/images/srpr/logo9w.png'},
                                {'image' => 'https://www.google.com/images/srpr/logo7w.png'}]
        @c = Content.create_from_import_job(@base_data)
      end

      it 'should have the right number of images' do
        expect(@c.images.length).to eq @base_data['images'].count
      end

      it 'should have a primary image' do
        image = @c.primary_image
        expect(image.image.url.present?).to be_truthy
        expect(image.source_url).to eq 'https://www.google.com/images/srpr/logo11w.png'
      end

      it 'should have the correct primary image' do #not necessarily the first
        @c.primary_image = @c.images.order('created_at asc').last
        @c.reload
        image = @c.primary_image
        expect(image.image.url.present?).to eq true
        expect(image.source_url).to eq 'https://www.google.com/images/srpr/logo7w.png'
      end

      it 'should have only one primary image' do
        @c.primary_image = @c.images.last
        expect(@c.images.where(primary: true).count).to eq 1
      end

      it 'should delete unused images' do
        expect(@c.images.length).to eq @base_data['images'].count
        expect(@c.images.find_by_source_url('https://www.google.com/images/srpr/logo11w.png')).not_to be_nil
        @base_data['images'] = [{'image' => 'https://www.google.com/images/srpr/logo7w.png'},
                                {'image' => 'https://www.google.com/images/srpr/logo9w.png'}]
        @c = Content.create_from_import_job(@base_data)
        expect(@c.images.length).to eq 2
        expect(@c.images.find_by_source_url('https://www.google.com/images/srpr/logo11w.png')).to be_nil
      end

      it 'should correctly handle rearranged images' do
        #first, verify the image array before making a change
        expect(@c.images.length).to eq @base_data['images'].count
        expect(@c.images.find_by_source_url('https://www.google.com/images/srpr/logo11w.png')).not_to be_nil
        expect(@c.images.find_by_source_url('https://www.google.com/images/srpr/logo9w.png')).not_to be_nil
        expect(@c.images.find_by_source_url('https://www.google.com/images/srpr/logo7w.png')).not_to be_nil
        expect(@c.images.find_by_source_url('https://www.google.com/images/srpr/logo6w.png')).to be_nil
        expect(@c.images.find_by_source_url('https://www.google.com/images/srpr/logo5w.png')).to be_nil

        # add some images, remove some others
        @base_data['images'] = [{'image' => 'https://www.google.com/images/srpr/logo5w.png'},
                                {'image' => 'https://www.google.com/images/srpr/logo6w.png'},
                                {'image' => 'https://www.google.com/images/srpr/logo7w.png'}]
        @c = Content.create_from_import_job(@base_data)

        # verify the resulting image array
        expect(@c.images.length).to eq 3
        expect(@c.images.find_by_source_url('https://www.google.com/images/srpr/logo11w.png')).to be_nil
        expect(@c.images.find_by_source_url('https://www.google.com/images/srpr/logo9w.png')).to be_nil
        expect(@c.images.find_by_source_url('https://www.google.com/images/srpr/logo7w.png')).not_to be_nil
        expect(@c.images.find_by_source_url('https://www.google.com/images/srpr/logo6w.png')).not_to be_nil
        expect(@c.images.find_by_source_url('https://www.google.com/images/srpr/logo5w.png')).not_to be_nil
        expect(@c.primary_image.name).to include('logo5w.png')
      end

    end
  end

  describe '#create_or_update_image' do
    subject { FactoryGirl.create :content }
    let(:image_url) { "https://www.google.com/images/srpr/logo11w.png" }
    before do
      google_logo_stub
    end

    context 'when image url already exist on record' do
      it 'updates existing image with the given url' do
        image = subject.create_or_update_image(image_url, "","")
        updated = subject.create_or_update_image(image_url, "New Caption", "")
        expect(updated.id).to eql image.id

        image.reload
        expect(image.caption).to eql 'New Caption'
      end
    end

    context 'primary' do
      it 'sets primary image to this image' do
        expect(subject.primary_image).to be_nil
        image = subject.create_or_update_image(image_url, "","", true)
        subject.reload
        expect(subject.primary_image).to_not be_nil
        expect(subject.primary_image).to eql image
      end
    end
  end

  describe "set guid if not present" do
    it "should set the guid of new content that has none" do
      content = FactoryGirl.create(:content)
      expect(content.guid).to eq("#{content.title.gsub(" ", "_").gsub("/", "-")}-#{content.pubdate.strftime("%Y-%m-%d")}")
    end
    it "should not overwrite the guid of new content that has a guid" do
      content = FactoryGirl.create(:content, guid: "Test-Guid")
      expect(content.guid).to eq("Test-Guid")
    end
  end

  describe "export to xml" do
    before do
      @content = FactoryGirl.create(:content)
    end
    after do
      # clean up output folder
      system("rm -rf #{Content::TMP_EXPORT_PATH}/*")
    end


    # fun note: we can assume certain attributes are present
    # after this test because quarantining guarantees that
    # those attributes are present, and export_to_xml doesn't work
    # and returns an error message if quarantine is true
    it "should not allow export of quarantined contents" do
      @content.quarantine = true
      # returns false if it fails to run
      expect(@content.export_to_xml nil).to_not eq(true)
    end

    it "should write xml and content to local corpus" do
      @content.export_to_xml nil
      expect(File.exists?("#{@content.export_path}/#{@content.guid}.xml")).to be_truthy
      expect(File.exists?("#{@content.export_path}/#{@content.guid}.html")).to be_truthy
      # check the content file includes the content
      file_content = ""
      File.open "#{@content.export_path}/#{@content.guid}.html", "r" do |f|
        f.each_line do |line|
          file_content << line
        end
      end
      expect(file_content.include?(@content.content)).to be_truthy

      # check the xml file includes some basic stuff like title
      log = Logger.new("#{Rails.root}/log/tests.log")
      log.debug "quarantine: #{@content.quarantine}"
      xml_content = File.open("#{@content.export_path}/#{@content.guid}.xml", "r").readlines.join()
      log.debug "path: #{@content.export_path}"
      log.debug "guid: #{@content.guid}"
      log.debug "full path: #{@content.export_path}/#{@content.guid}.xml"
      log.debug "xml_content: #{xml_content}"
      expect(xml_content.include?(@content.title)).to be_truthy
      expect(xml_content.include?(@content.pubdate.strftime(ContentDspSerializer::PUBDATE_OUTPUT_FORMAT))).to be_truthy
    end
  end

  describe "to new xml" do
    before do
      @content = FactoryGirl.create(:content)
      @image1 = FactoryGirl.create(:image)
      @image2 = FactoryGirl.create(:image)
      @xml = @content.to_xml(true)
    end

    it "should contain all the attributes as feature name/value pairs" do
      @content.feature_set.each do |k, v|
        unless ["content", "organization_id", "import_location_id", "parent_id",
                "issue_id", "content_category_id"].include? k
          # just checking with closing tags so we don't have to deal
          # with exact formatting of opening tag and attributes
          expect(@xml.include?("#{k.upcase}</tns:name>")).to be_truthy
          if v.present?
            # account for pubdate / timestamp formatting
            if k == "pubdate" or k == "timestamp"
              expect(@xml.include?("#{v.strftime(ContentDspSerializer::PUBDATE_OUTPUT_FORMAT)}</tns:value>")).to be_truthy
            # account for cdata
            elsif k == "authoremail" or k == "authors"
              expect(@xml.include?("#{v}]]></tns:value>")).to be_truthy
            else
              expect(@xml.include?("#{CGI::escapeHTML v}</tns:value>")).to be_truthy
            end
          end
        end
      end
    end

    # category_override was removed from org.  make sure this souldnt be updated
    # to something else.
    #
    # it "should use the organization's category_override if that is set" do
    #   @content.organization.update_attribute :category_override, "Test Category"
    #   expect(@content.to_xml.include?("Test Category")).to be_truthy
    # end

    it "should use the category-mapping instead of source_category if available" do
      cat = FactoryGirl.create(:category)
      @content.update_attribute :source_category, cat.name
      @content.update_attribute :category, nil
      expect(@content.to_xml.include?(cat.channel.name)).to be_truthy
    end

    it "should populate with a organization image if content doesnt have one" do
      @content.organization.images << @image1
      expect(@content.to_xml.include?("IMAGE</tns:name")).to be_truthy
    end

    it "should populate with content image if it exists" do
      @content.images << @image2
      expect(@content.to_xml.include?("IMAGE</tns:name")).to be_truthy
    end
    it "should contain document part with content" do
      # note the brackets at the end are closing CDATA
      expect(@xml.include?("#{@content.sanitized_content}]]></tns:content>")).to be_truthy
    end
  end

  describe "publish" do
    before do
      @content = FactoryGirl.create(:content)
      @repo = FactoryGirl.create(:repository)
    end

    after do
      # clean up output folder
      system("rm -rf #{Content::TMP_EXPORT_PATH}/*")
    end

    describe "#export_pre_pipeline_xml" do
      before do
        stub_request(:post, "http://#{@repo.dsp_endpoint.sub(/(?:http:\/\/)?(.*)\/?/, '\1')}/processPrePipeline").with(basic_auth: [
          Figaro.env.ontotext_api_username,
          Figaro.env.ontotext_api_password
        ]).to_return(:status => 200,
                     :body => File.open('spec/fixtures/pre_pipeline_output.xml', 'r').readlines.join(),
                     :headers => {})
        stub_request(:post, "http://#{@repo.dsp_endpoint.sub(/(?:http:\/\/)?(.*)\/?/, '\1')}/processPostPipeline").with(basic_auth: [
          Figaro.env.ontotext_api_username,
          Figaro.env.ontotext_api_password
        ]).to_return(:status => 200,
                    :body => File.open('spec/fixtures/post_pipeline_output.xml', 'r').readlines.join(),
                    :headers => {})
      end

      subject { @content.export_pre_pipeline_xml(@repo) }
      let(:base_path) { "#{@content.export_path}/pre_pipeline/#{@content.guid}" }

      it "should return true for successful export" do
        expect(subject).to be_truthy
      end

      it "should create xml and html files" do
        subject
        expect(File.exists? "#{base_path}.xml").to be_truthy
        expect(File.exists? "#{base_path}.html").to be_truthy
      end

      it "should have a well-formed XML file" do
        subject
        export = File.open("#{base_path}.xml", "r").readlines.join()
        expect(Nokogiri::XML(export) { |config| config.strict }).to_not be_nil
      end
    end

    describe "postpipeline xml" do
      before do
        stub_request(:post, "http://#{@repo.dsp_endpoint.sub(/(?:http:\/\/)?(.*)\/?/, '\1')}/processPostPipeline").with(basic_auth: [
          Figaro.env.ontotext_api_username,
          Figaro.env.ontotext_api_password
        ]).to_return(:status => 200,
                    :body => File.open('spec/fixtures/post_pipeline_output.xml', 'r').readlines.join(),
                    :headers => {})
      end

      subject { @content.export_post_pipeline_xml(@repo) }
      let(:base_path) { "#{@content.export_path}/post_pipeline/#{@content.guid}" }

      it "should return true for successful export" do
        expect(subject).to be_truthy
      end

      it "should create xml and html files" do
        subject
        expect(File.exists? "#{base_path}.xml").to be_truthy
        expect(File.exists? "#{base_path}.html").to be_truthy
      end

      it "should have a well-formed XML file" do
        subject
        export = File.open("#{base_path}.xml", "r").readlines.join()
        expect(Nokogiri::XML(export) { |config| config.strict }).to_not be_nil
      end
    end

    describe "during backup times" do
      it "should return false and not do anything" do
        Timecop.freeze(Chronic.parse("3:00 am")) do
          expect(@content.publish("post_to_ontotext", @repo)).to eq(false)
          expect(@repo.contents.include?(@content)).to eq(false)
        end
      end
    end

  end

  describe "publish_category" do
    before do
      @content = FactoryGirl.create(:content)
    end

    subject { @content.publish_category }

    describe "with source_category and category set" do
      it "should return category" do
        @content.category = "Test Subtext Category"
        @content.source_category = "Test Source Category"
        expect(subject).to eq("Test Subtext Category")
      end
    end

    describe "with only source_category set" do
      before do
        @content.category = nil
        @content.source_category = "Test Source Category"
      end

      describe "if no Category record exists" do
        it "should return the value of source_category" do
          expect(subject).to eq(@content.source_category)
        end

        it "should create a Category record with empty channel_id" do
          subject
          expect(Category.find_by_name(@content.source_category).present?).to eq(true)
        end
      end

      describe "if category exists with mapped channel" do
        it "should return the corresponding channel's name" do
          cat = FactoryGirl.create(:category)
          @content.source_category = cat.name
          expect(subject).to eq(cat.channel.name)
        end
      end
    end

  end

  describe "has_active_promotion?" do
    let(:content) { FactoryGirl.create(:content) }

    it "should return false if there are no promotions" do
      expect(content.has_active_promotion?).to eq(false)
    end

    it "should return false if there is a promotion banner but it is inactive" do
      FactoryGirl.create :promotion_banner, :inactive, content: content
      expect(content.has_active_promotion?).to eq(false)
    end

    it "should return true if there is an active promotion banner attached" do
      FactoryGirl.create :promotion_banner, :active, content: content
      expect(content.has_active_promotion?).to eq(true)
    end

  end

  describe '#has_promotion_inventory?' do
    let(:content) { FactoryGirl.create(:content) }
    subject { content.has_promotion_inventory? }

    context 'when related promotion banners have inventory' do
      before do
        FactoryGirl.create :promotion_banner, impression_count: 100, content: content
      end
      it 'returns true' do
        expect(subject).to be_truthy
      end
    end
  end

  describe '#has_active_promotion' do
    it 'is an alias for #has_active_promotion?' do
      expect(subject).to receive(:has_active_promotion?)
      subject.has_active_promotion
    end
  end

  describe '#has_paid_promotion' do
    it 'is an alias for #has_paid_promotion?' do
      expect(subject).to receive(:has_paid_promotion?)
      subject.has_paid_promotion
    end
  end

  describe '#has_promotion_inventory' do
    it 'is an alias for #has_promotion_inventory?' do
      expect(subject).to receive(:has_promotion_inventory?)
      subject.has_promotion_inventory
    end
  end

  describe '#rdf_to_gate' do
    subject { FactoryGirl.create :content }
    let(:repository) { FactoryGirl.build :repository }
    it 'passes id and repository argument to OntotextController' do
      expect(OntotextController).to receive(:rdf_to_gate).with(subject.id, repository)
      subject.rdf_to_gate(repository)
    end
  end

  describe "category" do
    before do
      @cat = FactoryGirl.create :content_category
      @content = FactoryGirl.create :content, content_category: @cat
    end

    it "should return the name of the attached content category" do
      expect(@content.category).to eq(@cat.name)
    end

  end

  describe "checking listserv locations on import" do
    before do
      @config = Hash.new
      @config["username"] = 'subtextuvltest@gmail.com'
      @config["password"] = 'RailRoad202'
      parser_path = Dir.pwd + "/lib/parsers/"
      @test_files_path = Dir.pwd + "/spec/fixtures/listserv_test_files"

      require parser_path + "mail_extractor.rb"

      google_logo_stub

      @norwich = FactoryGirl.create :location, city: 'Norwich', state: 'VT'
      @corinth = FactoryGirl.create :location, city: 'Corinth', state: 'VT'
      @topsham = FactoryGirl.create :location, city: 'Topsham', state: 'VT'
    end

    it "should create content with Norwich as location" do
      eml = Mail.read(@test_files_path+"/norwich.txt")
      parsed_emails = convert_eml_to_hasharray(eml, @config)

      expect(parsed_emails[0]['source'].include?('Listserv')).to eq(true)
      expect(parsed_emails[0]['content_locations'].length).to eq(1)
      expect(parsed_emails[0]['content_locations'].include?('Norwich,VT')).to eq(true)

      content = Content.create_from_import_job(parsed_emails[0])
      expect(Content.count).to eq(1)

      expect(content.locations.include?(@norwich)).to eq(true)
    end

    it "should create lrn locations" do
      eml = Mail.read(@test_files_path+"/lrn.txt")
      parsed_emails = convert_eml_to_hasharray(eml, @config)

      expect(parsed_emails[0]['source'].include?('Listserv')).to eq(true)
      expect(parsed_emails[0]['content_locations'].length).to eq(2)

      content = Content.create_from_import_job(parsed_emails[0])
      expect(Content.count).to eq(1)

      expect(content.locations.include?(@corinth)).to eq(true)

      expect(content.locations.include?(@topsham)).to eq(true)

    end


  end

  describe 'one location detected' do
    before do
      @config = Hash.new
      @config["username"] = 'subtextuvltest@gmail.com'
      @config["password"] = 'RailRoad202'
 
      parser_path = Dir.pwd + "/lib/parsers/"
      require parser_path + "mail_extractor.rb"
      @test_files_path = Dir.pwd + "/spec/fixtures/listserv_test_files"
      FactoryGirl.create :location, city: 'Norwich', state: 'VT'
    end

    it 'should mark the content location as "base"' do
      eml = Mail.read(@test_files_path+"/norwich.txt")
      parsed_emails = convert_eml_to_hasharray(eml, @config)

      content = Content.create_from_import_job(parsed_emails[0])
      expect(content.content_locations.count).to eq(1)
      expect(content.content_locations.first.location_type).to eql "base"
    end

  end

  describe 'multiple locations detected' do
    before do
      @config = Hash.new
      @config["username"] = 'subtextuvltest@gmail.com'
      @config["password"] = 'RailRoad202'
 
      parser_path = Dir.pwd + "/lib/parsers/"
      require parser_path + "mail_extractor.rb"
      @test_files_path = Dir.pwd + "/spec/fixtures/listserv_test_files"
      FactoryGirl.create :location, city: 'Norwich', state: 'VT'
      FactoryGirl.create :location, city: 'Corinth', state: 'VT'
    end

    it 'should not mark any content location as "base"' do
      eml = Mail.read(@test_files_path+"/norwich.txt")
      parsed_emails = convert_eml_to_hasharray(eml, @config)
      parsed_emails[0]['content_locations'] << "Corinth, VT"

      content = Content.create_from_import_job(parsed_emails[0])
      expect(content.content_locations.count).to eq(2)
      location_types = content.content_locations.map(&:location_type)
      expect(location_types).to all( eql("base"))
    end
  end

  describe 'checking upper valley locations on import' do

    before do
      parser_path = Dir.pwd + "/lib/parsers/"
      @test_files_path = Dir.pwd + "/spec/fixtures/upper_valley_list_test_files"

      require parser_path + "upper_valley_list_parser.rb"

      @upper_valley = FactoryGirl.create :location
      @upper_valley.city = "Upper Valley"
      @upper_valley.state = nil
      @upper_valley.save

    end


    it 'should create Upper Valley location' do

      body = get_body_from_file("/TwoEntries.html")
      results = []
      all_posts = find_posts(body)
      parse_posts(all_posts, results)

      content = Content.create_from_import_job(results[0])
      expect(Content.count).to eq(1)
      expect(content.locations.include?(@upper_valley)).to eq(true)
    end

  end

  describe 'get_comment_thread' do
    before do
      @root = FactoryGirl.create :content
    end

    subject { @root.get_comment_thread }

    it 'should return an empty list if content has no children' do
      expect(subject).to eq([])
    end

    it 'should not include any children that are not comment channel' do
      FactoryGirl.create :content, parent_id: @root.id
      expect(subject).to eq([])
    end

    it 'should return content with the transient attribute "tier" set' do
      tier0 = FactoryGirl.create :comment
      tier0.content.update_attribute :parent_id, @root.id
      expect(subject).to eq([tier0.content])
      expect(subject[0].tier).to eq(0)
    end

    it 'correctly assigns tiers to the whole tree' do
      tier0 = FactoryGirl.create :comment
      tier0.content.update_attribute :parent_id, @root.id
      tier0_2 = FactoryGirl.create :comment
      tier0_2.content.update_attribute :parent_id, @root.id
      tier1 = FactoryGirl.create :comment
      tier1.content.update_attribute :parent_id, tier0.content.id
      tier2 = FactoryGirl.create :comment
      tier2.content.update_attribute :parent_id, tier1.content.id
      expect(subject.count).to eq(4)
      tier_counts = []
      subject.each do |com|
        tier_counts[com.tier] ||=0
        tier_counts[com.tier] +=1
      end
      expect(tier_counts[0]).to eq(2)
      expect(tier_counts[1]).to eq(1)
      expect(tier_counts[2]).to eq(1)
    end

  end

  describe 'one post to multiple listservs' do

    before do
      @config = Hash.new
      @config["username"] = 'subtextuvltest@gmail.com'
      @config["password"] = 'RailRoad202'
      parser_path = Dir.pwd + "/lib/parsers/"
      @test_files_path = Dir.pwd + "/spec/fixtures/one_message_multiple_listservs"

      require parser_path + "mail_extractor.rb"

      @strafford = FactoryGirl.create :location, city: 'Strafford', state: 'VT'
      @new_london = FactoryGirl.create :location, city: 'New London', state: 'NH'

    end

    it 'should be one post and two entries in content_locations for each listserv' do

      eml = Mail.read(@test_files_path+"/strafford.txt")
      parsed_emails = convert_eml_to_hasharray(eml, @config)
      content = Content.create_from_import_job(parsed_emails[0])
      expect(Content.count).to eq(1)
      expect(content.locations.include?(@strafford)).to eq(true)
      id_1 = content.id

      eml = Mail.read(@test_files_path+"/new_london.txt")
      parsed_emails = convert_eml_to_hasharray(eml, @config)
      content = Content.create_from_import_job(parsed_emails[0])
      expect(Content.count).to eq(1)
      expect(content.locations.include?(@new_london)).to eq(true)
      id_2 = content.id

      expect(id_1).to eq(id_2)
      expect(content.locations.length).to eq(2)
      expect(content.locations.include?(@new_london)).to eq(true)
      expect(content.locations.include?(@strafford)).to eq(true)

      # Should all as base
      expect(content.content_locations.base.map(&:location_type)).to all( eql('base'))
    end
  end

  # the test input and expected output is kept outside the test in spec/fixtures/sanitized_content
  # each _input file must have a matching named file ending with _output.
  describe 'when user sends raw content' do
    input_files = Dir['spec/fixtures/sanitized_content/*_input']
    output_files = Dir['spec/fixtures/sanitized_content/*_output']
    raise 'unable to find any input files for this test!' if input_files.blank?

    input_files.each do |input_file|
      it "from #{input_file}" do
        output_file = input_file.gsub '_input', '_output'
        raise 'expected sanitized output file not found' unless output_files.include? output_file
        raw_content = File.read input_file
        content = FactoryGirl.create :content , raw_content: raw_content
        expect(content.sanitized_content).to eq File.read(output_file).chomp
      end
    end
  end

  describe '#remove_boilerplate' do
    input_files = Dir['spec/fixtures/sanitized_content/*_input']
    let!(:blacklisted_content) {File.readlines(Rails.root.join('lib', 'content_blacklist.txt'))}
    input_files.each do |input_file|
      context "from #{input_file}" do
        it 'strips blacklisted content' do
          raw_content = File.read input_file
          content = FactoryGirl.create :content , raw_content: raw_content
          bp_removed = content.remove_boilerplate

          blacklisted_content.each do |blc|
            expect(bp_removed).to_not include(blc)
          end
        end
      end
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

  describe '#talk_comments' do
    let(:talk_category) { FactoryGirl.create :content_category, name: 'talk_of_the_town' }
    let(:discussion_category) { FactoryGirl.create :content_category, name: 'discussion' }
    before do
      @content = FactoryGirl.create :content, content_category: talk_category
      @comment_content1 = FactoryGirl.create :content, content_category: talk_category
      @comment_content2 = FactoryGirl.create :content, content_category: talk_category
      @comment1 = FactoryGirl.create :comment, content: @comment_content1
      @comment1.content.update_attributes(parent_id: @content.id, root_content_category_id: talk_category)
      @comment2 = FactoryGirl.create :comment, content: @comment_content2
      @comment2.content.update_attributes(parent_id: @content.id, root_content_category_id: discussion_category)
    end

    it 'returns content records of comments associated to a talk item' do
      expect(@content.talk_comments).to include(@comment1.content, @comment2.content)
    end
  end

  describe 'process_wp_content!' do
    before do
      raw_content = '<p>hello</p><img src="http://www.google.com/testing.jpg" /> <p>blargh</p><img src="http://www.google.com/photo.jpg" />'
      @content = FactoryGirl.create :content, raw_content: raw_content
      @img = FactoryGirl.create :image, imageable: @content, caption: 'This is a unique string',
        source_url: 'http://www.google.com/photo.jpg'
      @img2 = FactoryGirl.create :image, imageable: @content, caption: 'SFDSFDS', image: nil,
        source_url: 'http://www.google.com/testing.jpg', primary: true
    end

    subject { @content.process_wp_content! }

    it 'should remove the first image tag from any content with images' do
      expect{subject}.to change{@content.raw_content.scan('<img').length}.by -1
    end

    it 'should find and replace urls to match our copied images' do
      subject
      expect(@content.reload.raw_content).to include(@img.image.url)
    end

    it 'should add a caption if a caption is present' do
      subject
      expect(@content.reload.raw_content).to include(@img.caption)
    end

    describe 'without the primary image' do
      before do
        @content.update_attribute :raw_content, '<p>hello</p><p>blargh</p><img src="http://www.google.com/photo.jpg" />'
      end

      it 'should not remove any image tags' do
        expect{subject}.not_to change{@content.raw_content.scan('<img').length}
      end
    end

    describe 'with some images already converted' do
      before do
        @content.process_wp_content! # process once
        # add some new images
        @content.raw_content += '<p><img src="http://www.google.com/photo2.jpg" /></p>'
        @content.save
        @img3 = FactoryGirl.create :image, imageable: @content, caption: 'Humdeedum',
          source_url: 'http://www.google.com/photo2.jpg', image: File.open(File.join(Rails.root, '/spec/fixtures/photo2.jpg'))
      end

      it 'should have all images correctly handled' do
        subject
        @content.reload
        expect(@content.raw_content).to include(@img.image.url)
        expect(@content.raw_content).to include(@img3.image.url)
        expect(@content.raw_content).not_to include('testing.jpg') # since img2 is primary
      end
    end

  end

  describe 'callbacks for denormalized attributes' do
    before do
      @parent = FactoryGirl.create :content
      @cat = FactoryGirl.create :content_category
      @content = FactoryGirl.build :content, parent: @parent, content_category: @cat
    end

    subject { @content.save }

    describe 'set_root_content_category_id' do
      it 'should set root_content_category_id' do
        expect{subject}.to change{@content.root_content_category_id}.to @cat.id
      end

      it 'should set root_content_category_id appropriately if the categoryt is not the root' do
        cat2 = FactoryGirl.create :content_category
        @cat.update_attribute :parent_id, cat2.id
        expect{subject}.to change{@content.root_content_category_id}.to cat2.id
      end
    end

    describe 'set_root_parent_id' do
      it 'should set root_parent_id' do
        expect{subject}.to change{@content.root_parent_id}.to @parent.id
      end

      it 'should set root_parent_id appropriately if the parent is not the root' do
        parent2 = FactoryGirl.create :content
        @parent.update_attribute :parent_id, parent2.id
        expect{subject}.to change{@content.root_parent_id}.to parent2.id
      end

      it 'should set root_parent_id to self.id when no parent exists' do
        c = FactoryGirl.create :content
        expect(c.root_parent_id).to eq c.id
      end

      context 'for existing content' do
        it 'should update the root_parent_id if parent_id changes' do
          @content.save
          @content.parent = nil
          expect{@content.save}.to change{@content.root_parent_id}.to @content.id
        end
      end
    end
  end

  describe 'Content.search', elasticsearch: true do
    describe 'authors' do
      before do
        @user = FactoryGirl.create :user
        @news = FactoryGirl.create :content,
          content_category: FactoryGirl.create(:content_category, name: 'news'),
          created_by: @user
        @not_news = FactoryGirl.create :content, created_by: @user
      end

      it 'should index authors for news content' do
        expect(Content.search(@news.authors).results).to eq([@news])
      end

      it 'should index created_by.name if available for non-news content' do
        expect(Content.search(@user.name).results).to eq([@not_news])
      end
    end

    describe 'organization name' do
      before do
        @content = FactoryGirl.create :content
      end

      it 'should index organization name' do
        expect(Content.search(@content.organization.name).results).to eq([@content])
      end
    end
  end

  describe 'Content.talk_search', elasticsearch: true do
    before do
      @talk = FactoryGirl.create :content_category, name: 'talk_of_the_town'
      @p1 = FactoryGirl.create :content, content_category: @talk, pubdate: 1.year.ago
      @p2 = FactoryGirl.create :content, content_category: @talk, pubdate: 1.week.ago
      @p3 = FactoryGirl.create :content, content_category: @talk, pubdate: 1.day.ago
      @p1c1 = FactoryGirl.create :content, parent: @p1, content_category: @talk,
        raw_content: 'VERY UNIQUE STRING @#$#%'
      @p1c2 = FactoryGirl.create :content, parent: @p1c1, content_category: @talk,
        raw_content: 'DIFFSTRING912387'
      @p2c1 = FactoryGirl.create :content, parent: @p2, content_category: @talk,
        raw_content: 'adsfdsafds', pubdate: 3.hours.ago
    end

    it 'should group search results by root_parent_id' do
      [Content.talk_search(@p1c1.raw_content), Content.talk_search(@p1c2.raw_content)].each do |results|
        expect(results[:results]).to include(@p1)
        expect(results[:results].length).to eq 1
      end
    end

    it 'should group properly with no query' do
      results = Content.talk_search[:results]
      expect(results).to include(@p1)
      expect(results).to include(@p2)
      expect(results).to include(@p3)
    end

    describe 'result order' do
      it 'should order by the latest activity' do
        # @p1 has an earlier pubdate than @p2, but one of its comments has a later pubdate (@c2),
        # so it should show up first in the results based on its 'latest_activity'
        expect(Content.talk_search[:results]).to match_array([@p1, @p2, @p3])
      end
    end

    describe 'paging' do
      it 'should return the requested number of results' do
        expect(Content.talk_search(nil, { per_page: 1 })[:results].count).to eq 1
      end

      it 'should return different results when requesting a later page' do
        expect(Content.talk_search(nil, { per_page: 1, page: 1 })[:results]).to_not match_array(
          Content.talk_search(nil, { per_page: 1, page: 2 })[:results])
      end
    end
  end

  describe 'increment_view_count!' do
    before do
      @published_content = FactoryGirl.create(:content, published: true)
      @unpublished_content = FactoryGirl.create(:content, published: false)
    end

    it 'should increment the view count' do
      expect{@published_content.increment_view_count!}.to change{@published_content.view_count}.by 1
    end

    it 'should not increment the view count if not published' do
      expect{@unpublished_content.increment_view_count!}.not_to change{@unpublished_content.view_count}
    end

    context 'for a user with skip_analytics = true' do
      before do
        @user = FactoryGirl.create :user, skip_analytics: true
        User.current = @user
        @news_content_category   = FactoryGirl.create :content_category, name: "news"
        @event_content_category = FactoryGirl.create :content_category, name: "event"
      end

      it 'should not increment the view count' do
        expect{@unpublished_content.increment_view_count!}.not_to change{@unpublished_content.view_count}
      end

      it 'should not increment if the root content is news' do
        @published_content.update_attributes(content_category: @news_content_category)
        @published_content.save!
        expect{@published_content.increment_view_count!}.not_to change{@published_content.view_count}
      end

      it 'should increment view count for other channels' do
        @published_content.update_attributes(content_category: @event_content_category)
        @published_content.save!
        expect{@published_content.increment_view_count!}.to change{@published_content.view_count}
      end
    end
  end

  describe '.if_event_only_when_instances scope;' do
    subject { Content.if_event_only_when_instances.to_a }

    context 'when event exists with instances' do
      let!(:event) { FactoryGirl.create :event }

      it 'includes the event content' do
        expect( subject ).to include(event.content)
      end
    end

    context 'When event exists containing no instances' do
      let!(:event_no_instances) { FactoryGirl.create :event, skip_event_instance: true }

      it 'does not include the event content' do
        expect( subject ).to_not include(event_no_instances.content)
      end
    end

    context "When non-event content exists" do
      let!(:other_content) { FactoryGirl.create :content }

      it 'includes content' do
        expect( subject ).to include(other_content)
      end
    end

    context 'When mixed event ( with no instances ), and other content exist' do
      let!(:event_no_instances) { FactoryGirl.create :event, skip_event_instance: true }
      let!(:other_content) { FactoryGirl.create :content }

      it 'includes other content, but not events with no instances' do
        expect( subject ).to include(other_content)
        expect( subject ).to_not include(event_no_instances)
      end
    end
  end

  describe 'similar_content' do
    context 'with similar_content_overrides present' do
      before do
        @override3 = FactoryGirl.create :content, pubdate: 1.week.ago
        @override1 = FactoryGirl.create :content, pubdate: 1.day.ago
        @override2 = FactoryGirl.create :content, pubdate: 3.days.ago
        @ids = [@override1, @override2, @override3].map{ |o| o.id }
        @content = FactoryGirl.create(:content, similar_content_overrides: @ids)
        @repo = FactoryGirl.create :repository
      end

      it 'should return the contents specified as overrides' do
        result_ids = @content.similar_content(@repo).map{ |c| c.id }
        @ids.each {|id| expect(result_ids).to include id }
      end

      it 'should return the contents in pubdate DESC order' do
        expect(@content.similar_content(@repo)).to eq [@override1, @override2, @override3]
      end
    end

    it 'returns contents in same order as DSP service' do
      repo = FactoryGirl.build_stubbed :repository
      content = FactoryGirl.build_stubbed :content
      similar = FactoryGirl.create_list(:content, 8).shuffle
      allow(DspService).to receive(:get_similar_content_ids).with(
        content, 8, repo
      ).and_return(similar.collect(&:id))

      expect(content.similar_content(repo, 8).map(&:id)).to eql similar.map(&:id)
    end
  end

  describe 'title=t' do
    it 'should automatically strip the title attribute' do
      c = FactoryGirl.create :content, title: '   This has Whitespace at Beginning And End  '
      expect(c.title).to eq c.title.strip
    end
  end

  describe '#ux2_uri' do
    context 'No root content category' do
      before do
        subject.root_content_category = nil
      end

      it 'is ""' do
        expect(subject.ux2_uri).to eql ""
      end
    end

    context 'root content category' do
      let(:category) { FactoryGirl.create :content_category }
      before do
        subject.root_content_category = category
      end

      it 'is "/{root_content_category.name}/{id}"' do
        expect(subject.ux2_uri).to eql "/#{category.name}/#{subject.id}"
      end
    end
  end

  describe "#sanitized_title" do
    context "when no title present" do
      it "returns nil" do
        content = FactoryGirl.create :content, title: nil
        expect(content.sanitized_title).to be_nil
      end
    end

    context "when title present" do
      it "returns title" do
        content = FactoryGirl.create :content, title: 'In a galaxy...'
        expect(content.sanitized_title).to eq content.title
      end
    end

    context "when title is only listserv name" do
      it "returns 'Post by...' title" do
        user = FactoryGirl.create :user, name: 'Han Solo'
        content = FactoryGirl.create :content, title: "[Hoth]",
          created_by: user
        expect(content.sanitized_title).to include "Han Solo"
      end
    end
  end

  describe 'sanitized_content=' do
    it 'sets raw_content' do
      content = 'Test Content'
      expect(subject).to receive(:raw_content=).with(content)
      subject.sanitized_content= content
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

    context 'for content without a specific sanitizer' do
      before { @content = FactoryGirl.create :content, origin: nil }

      it' should use the default_sanitized_content method' do
        expect(@content).to receive(:default_sanitized_content)
        subject
      end

      it 'should match output of default_sanitized_content' do
        expect(subject).to eq @content.default_sanitized_content
      end
    end
  end

  describe '#author_name' do
    before do
      @content = FactoryGirl.create :content, authors: Faker::Name.name
      @content.update_column :created_by, nil
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
        @content.content_category = FactoryGirl.build :content_category, name: 'news'
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

    context 'for content with a root category of news' do
      before do
        @content.root_content_category = FactoryGirl.build :content_category, name: 'news'
        @content.created_by = user
      end

      it { should eql @content.authors }
    end
  end

  describe '#is_news_ugc?' do
    let(:news_cat) { FactoryGirl.build :content_category, name: 'news' }
    subject { content.is_news_ugc? }
    describe 'for news UGC' do
      let (:content) { FactoryGirl.build :content, origin: Content::UGC_ORIGIN,
                       content_category: news_cat }
      it { should be true }
    end

    describe 'for other content' do
      let(:content) { FactoryGirl.build :content }
      it { should be false }
    end
  end

  describe '#is_news_child_category?' do
    let(:root_content) { FactoryGirl.build :content_category, name: 'news' }
    subject { content.is_news_child_category? }
    describe 'check if content has a root_category of `news`' do
      let(:content) { FactoryGirl.build :content, root_content_category: root_content }
      it { should be true }
    end
  end

  describe "#current_daily_report" do
    before do
      @content_category = FactoryGirl.build :content_category, name: 'news'
      @news = FactoryGirl.create :content, content_category_id: @content_category.id
    end

    subject { @news.current_daily_report }

    context "when no daily report present" do
      before do
        @content_report = FactoryGirl.create :content_report, report_date: Date.yesterday
        @news.content_reports << @content_report
      end

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "when daily report present" do
      before do
        @content_report = FactoryGirl.create :content_report, report_date: Date.current
        @news.content_reports << @content_report
      end

      it "returns current report" do
        expect(subject).to eq @content_report
      end
    end
  end

  describe "#find_or_create_daily_report" do
    before do
      @content_category = FactoryGirl.build :content_category, name: 'news'
      @news = FactoryGirl.create :content, content_category_id: @content_category.id
    end

    subject { @news.find_or_create_daily_report }

    context "when no report present" do
      it "creates daily report" do
        expect{ subject }.to change{
          @news.reload.content_reports.count
        }.by 1
      end
    end

    context "when current report available" do
      before do
        @content_report = FactoryGirl.create :content_report, report_date: Date.current
        @news.content_reports << @content_report
      end

      it "returns current report" do
        expect(subject).to eq @content_report
      end
    end
  end

  describe "#split_content" do
    before do
      @content = FactoryGirl.create :content
      allow_any_instance_of(SplitContentForAdPlacement).to receive(:call)
        .and_return(true)
    end

    subject { @content.split_content }

    it "makes call to content splitting process" do
      expect(SplitContentForAdPlacement).to receive(:call).with(@content.sanitized_content)
      subject
    end
  end

  describe 'my_town_only?' do
    context 'multiple content locations, some as base' do
      before do
        subject.content_locations = [
          FactoryGirl.build_stubbed(:content_location, location_type: 'base'),
          FactoryGirl.build_stubbed(:content_location, location_type: nil)
        ];
      end

      it 'is false' do
        expect(subject.my_town_only?).to be false
      end
    end

    context 'multiple content locations, all as base' do
      before do
        subject.content_locations = [
          FactoryGirl.build_stubbed(:content_location, location_type: 'base'),
          FactoryGirl.build_stubbed(:content_location, location_type: 'base')
        ];
      end

      it 'is true' do
        expect(subject.my_town_only?).to be true
      end
    end

    context 'organization locations' do
      before do
        subject.organization = FactoryGirl.build :organization
      end

      describe 'when organization has non-base locations, and content does not' do
        before do
          subject.content_locations = [
            FactoryGirl.build_stubbed(:content_location, location_type: 'base'),
            FactoryGirl.build_stubbed(:content_location, location_type: 'base')
          ];

          subject.organization.organization_locations = [
            FactoryGirl.build_stubbed(:organization_location, location_type: nil),
            FactoryGirl.build_stubbed(:organization_location, location_type: nil)
          ];
        end

        it 'is false' do
          expect(subject.my_town_only?).to be false
        end
      end

      describe 'when organization, and content has only base locations' do
        before do
          subject.content_locations = [
            FactoryGirl.build_stubbed(:content_location, location_type: 'base'),
            FactoryGirl.build_stubbed(:content_location, location_type: 'base')
          ];

          subject.organization.organization_locations = [
            FactoryGirl.build_stubbed(:organization_location, location_type: 'base'),
            FactoryGirl.build_stubbed(:organization_location, location_type: 'base')
          ];
        end

        it 'is true' do
          expect(subject.my_town_only?).to be true
        end
      end
    end
  end

  private

    def get_body_from_file(filename)

      f = File.open(@test_files_path + filename)
      body = ""

      f.each_line do |line|
        body << line
      end
      f.close

      body
    end

end
