# == Schema Information
#
# Table name: listserv_contents
#
#  id                         :integer          not null, primary key
#  listserv_id                :integer
#  sender_name                :string(255)
#  sender_email               :string(255)
#  subject                    :string(255)
#  body                       :text(65535)
#  content_category_id        :integer
#  subscription_id            :integer
#  key                        :string(255)
#  verification_email_sent_at :datetime
#  verified_at                :datetime
#  pubdate                    :datetime
#  content_id                 :integer
#  user_id                    :integer
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
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

end
