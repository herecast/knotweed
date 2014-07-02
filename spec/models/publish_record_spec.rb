require 'spec_helper'

describe PublishRecord do
  before { @publish_record = FactoryGirl.create(:publish_record) }

  describe "#files" do
    subject { @publish_record.files }

    context "first call" do
      it "should create a new, empty array" do
        expect(subject).to be_a(Array)
        expect(subject).to have(0).entries
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
