# == Schema Information
#
# Table name: publish_records
#
#  id              :integer          not null, primary key
#  publish_job_id  :integer
#  items_published :integer          default(0)
#  failures        :integer          default(0)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

require 'spec_helper'

describe PublishRecord, :type => :model do
  before { @publish_record = FactoryGirl.create(:publish_record) }

  describe "#files" do
    subject { @publish_record.files }

    context "first call" do
      it "should create a new, empty array" do
        expect(subject).to be_a(Array)
        expect(subject.entries.size).to eq(0)
      end
    end

    context "subsequent calls" do
      let (:path) { "my_file_path.txt" }
      before { @publish_record.files << path }

      it "should return an array containing the previous array contents" do
        expect(subject).to be_a(Array)
        expect(subject).to include path
      end
    end
  end
end
