require 'rails_helper'

RSpec.describe MakeSunsettedContentPrivate, type: :job do
  describe "#perform" do
    subject { MakeSunsettedContentPrivate.perform_now }

    context "when Content does not have sunset_date" do
      before do
        @content = FactoryGirl.create :content, biz_feed_public: true
      end

      it "does not change biz_feed_public to false" do
        expect { subject }.not_to change {
          @content.reload.biz_feed_public
        }
      end
    end

    context "when Content has sunset_date in future" do
      before do
        @content = FactoryGirl.create :content,
                                      biz_feed_public: true,
                                      sunset_date: Date.tomorrow
      end

      it "does not change biz_feed_public to false" do
        expect { subject }.not_to change {
          @content.reload.biz_feed_public
        }
      end
    end

    context "when Content has sunset_date in past" do
      before do
        @content = FactoryGirl.create :content,
                                      biz_feed_public: true,
                                      sunset_date: Date.yesterday
      end

      it "changes biz_feed_public to false" do
        expect { subject }.to change {
          @content.reload.biz_feed_public
        }.to false
      end
    end
  end
end
