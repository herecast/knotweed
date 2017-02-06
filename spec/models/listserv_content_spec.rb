# == Schema Information
#
# Table name: listserv_contents
#
#  id                         :integer          not null, primary key
#  listserv_id                :integer
#  sender_name                :string
#  sender_email               :string
#  subject                    :string
#  body                       :text
#  content_category_id        :integer
#  subscription_id            :integer
#  key                        :string
#  verification_email_sent_at :datetime
#  verified_at                :datetime
#  pubdate                    :datetime
#  content_id                 :integer
#  user_id                    :integer
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  verify_ip                  :string
#  deleted_at                 :datetime
#  deleted_by                 :string
#

require 'rails_helper'

RSpec.describe ListservContent, type: :model do
  it { is_expected.to have_db_column(:body) }
  it { is_expected.to have_db_column(:subject) }
  it { is_expected.to have_db_column(:key) }
  it { is_expected.to have_db_column(:verification_email_sent_at) }
  it { is_expected.to have_db_column(:verified_at) }
  it { is_expected.to have_db_column(:pubdate) }
  it { is_expected.to have_db_column(:sender_email) }
  it { is_expected.to have_db_column(:sender_name) }
  it { is_expected.to have_db_column(:verify_ip) }

  it { is_expected.to belong_to(:listserv) }
  it { is_expected.to belong_to(:content_category) }
  it { is_expected.to belong_to(:subscription) }
  it { is_expected.to belong_to(:content) }
  it { is_expected.to belong_to(:user) }

  describe 'validation' do
    it {is_expected.to validate_uniqueness_of(:key)}
    it {is_expected.to validate_presence_of(:key)}
    it {is_expected.to validate_presence_of(:listserv)}
    it {is_expected.to validate_presence_of(:body)}
    it {is_expected.to validate_presence_of(:subject)}
    it {is_expected.to validate_presence_of(:sender_email)}

    context 'when verified' do
      before do
        subject.verified_at = Time.current
      end

      it 'requires verify_ip' do
        expect(subject).to_not be_valid
        expect(subject.errors[:verify_ip]).to include("can't be blank")
      end
    end
  end

  describe 'soft deletion' do
    it{ is_expected.to have_db_column(:deleted_at) }

    context 'when deleted_at set' do
      subject{ FactoryGirl.create :listserv_content, deleted_at: Time.now }

      it 'does not return from active record queries' do
        expect(ListservContent.all.to_a).to_not include(subject)
      end
    end
  end

  describe '#key' do
    subject { FactoryGirl.create :listserv_content }
    it 'is generated automatically' do
      random_key = SecureRandom.uuid
      allow(SecureRandom).to receive(:uuid).and_return(random_key)
      expect(subject.key).to eql random_key
    end
  end

  describe '#channel_type' do
    context 'when in top level content category;' do
      let(:category) {FactoryGirl.create :content_category}
      before do
        subject.content_category = category
      end

      it 'is equal to content_category.name sym' do
        expect(subject.channel_type).to eql category.name.to_sym
      end
    end

    context 'when in child content_category;' do
      let(:parent) {FactoryGirl.create :content_category}
      let(:category) {FactoryGirl.create :content_category, parent: parent}
      before do
        subject.content_category = category
      end

      it 'is equal to content_category.parent.name sym' do
        expect(subject.channel_type).to eql parent.name.to_sym
      end
    end

    context 'when category is "talk_of_the_town"' do
      let(:category) { FactoryGirl.create :content_category, name: 'talk_of_the_town' }
      before do
        subject.content_category = category
      end

      it 'is ":talk"' do
        expect(subject.channel_type).to eql :talk
      end
    end
  end

  describe '#channel_type=' do
    context 'Given the symbolized name of a category' do
      let(:category) { FactoryGirl.create :content_category }

      it 'sets the category on the record' do
        expect{ subject.channel_type= category.name.to_sym }.to change{
          subject.content_category
        }.to category
      end

      context 'When category name is "talk_of_the_town";' do
        let!(:category) { FactoryGirl.create :content_category, name: 'talk_of_the_town'}

        context 'Given ":talk"' do
          it 'sets the content_category to the talk_of_the_town category' do
            expect{ subject.channel_type= :talk }.to change{
              subject.content_category
            }.to category
          end
        end
      end
    end
  end

  describe "#categorized?" do
    let(:listserv_content) { FactoryGirl.create :listserv_content }

    context "when not categorized" do
      it "returns false" do
        expect(listserv_content.categorized?).to be false
      end
    end

    context "when categorized" do
      let!(:content_category) { FactoryGirl.create :content_category }
      let(:listserv_content) { FactoryGirl.create :listserv_content, content_category_id: content_category.id }

      it "returns true" do
        expect(listserv_content.categorized?).to be true
      end
    end
  end

  describe "#published?" do
    context "when content is not published" do
      let(:listserv_content) { FactoryGirl.create :listserv_content, pubdate: nil }

      it "returns false" do
        expect(listserv_content.published?).to be false
      end
    end

    context "when content is published" do
      let(:listserv_content) { FactoryGirl.create :listserv_content, pubdate: Date.yesterday }

      it "returns true" do
        expect(listserv_content.published?).to be true
      end
    end
  end

  describe 'ascii_body' do
    context 'when #body has non ASCII recognized characters' do
      subject { ListservContent.new }

      before do
        subject.body =
          'They say the Lion and the Lizard keep
            The Courts where Janshyd gloried and drank deep
            And Bahram, that great Hunter � the Wild Ass
            Stamps o�er his Head, and he lies fast asleep'
      end

      it 'strips out the characters' do
        expect(subject.ascii_body).to eql "They say the Lion and the Lizard keep
            The Courts where Janshyd gloried and drank deep
            And Bahram, that great Hunter  the Wild Ass
            Stamps oer his Head, and he lies fast asleep"
      end
    end

    context "when no body present" do
      before do
        subject.update_attribute(:body, nil)
      end

      it "returns blank string" do
        expect(subject.ascii_body).to eq ""
      end
    end
  end

  describe "#publish_content" do
    let(:listserv_content) { FactoryGirl.create :listserv_content, body: '<p>hi, Jaba</p>' }

    context "when tags are meant to be included" do
      it "returns content with tags" do
        expect(listserv_content.publish_content(true)).to eq listserv_content.body
      end
    end

    context "when tags are meant to be removed" do
      it "returns body stripped of tags" do
        expect(listserv_content.publish_content).to eq "hi, Jaba"
      end
    end
  end

  describe "#feature_set" do
    before do
      @listserv_content = FactoryGirl.create :listserv_content, subject: 'Pod racing, 101'
    end

    it "returns accurate feature set" do
      expect(@listserv_content.feature_set).to include(
        "title" => @listserv_content.subject,
        "source" => "Listserv",
        "classify_only" => true
      )
    end
  end

  describe "#document_uri" do
    before do
      @listserv_content = FactoryGirl.create :listserv_content
    end

    it "returns blank string" do
      expect(@listserv_content.document_uri).to eq ""
    end
  end

  describe 'sender_email=' do
    context 'Given an email with capitals' do
      let(:email) { "TestEr@example.COM" }

      it 'transforms to lowercase' do
        subject.sender_email = email
        expect(subject.sender_email).to eql 'tester@example.com'
      end
    end
  end

  describe '#update_from_content' do
    context 'Given a content record' do
      let(:content) { FactoryGirl.create(:content, created_by: FactoryGirl.create(:user)) }
      subject { described_class.new }
      before do
        subject.update_from_content content
      end

      it 'has matching subject to content.title' do
        expect(subject.subject).to eql content.title
      end

      it 'has body to sanitized content' do
        expect(subject.body).to eql content.sanitized_content
      end

      it 'sets content_id reference' do
        expect(subject.content_id).to eql content.id
      end

      it 'sets user' do
        expect(subject.user).to eql content.created_by
      end

      it 'sets email' do
        expect(subject.sender_email).to eql content.created_by.email
      end

      it 'sets name' do
        expect(subject.sender_name).to eql content.created_by.name
      end

      it 'has matching category to content root category' do
        expect(subject.content_category).to eql content.root_content_category
      end
    end
  end

  describe '#sent_in_digest?' do
    let(:content) { FactoryGirl.create :content }
    let(:listserv) { FactoryGirl.create :listserv }

    subject{
      FactoryGirl.create :listserv_content,
        listserv: listserv,
        content: content
    }


    context 'When no digest with record in listserv_content_ids' do
      it 'is false' do
        expect(subject.sent_in_digest?).to be false
      end
    end

    context 'When digest exists with record in listsrv_content_ids' do
      let!(:digest) {
        FactoryGirl.create :listserv_digest,
          listserv: listserv,
          listserv_content_ids: [subject.id]
      }

      it 'is true' do
        expect(subject.sent_in_digest?).to be true
      end
    end
  end

  describe '#author_name' do
    before do
      subject.sender_name = 'Daniel Johns'
    end

    it 'is the sender_name' do
      expect(subject.author_name).to eql subject.sender_name
    end

    context 'when user is linked' do
      let(:user) { User.new(name: 'Kurt Cobain') }

      before do
        subject.user = user
      end

      it 'should be the user name' do
        expect(subject.author_name).to eql user.name
      end
    end
  end

end
