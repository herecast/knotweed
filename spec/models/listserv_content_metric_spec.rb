require 'rails_helper'

RSpec.describe ListservContentMetric, type: :model do
  context "when ListservContentMetric does not have a ListservContent record" do
    it "is not valid" do
      listserv_content_metric = FactoryGirl.build :listserv_content_metric, listserv_content_id: nil
      expect(listserv_content_metric).to_not be_valid
    end
  end

  context "when ListservContentMetric has a ListservContent record" do
    it "is valid" do
      listserv_content = FactoryGirl.create :listserv_content
      listserv_content_metric = FactoryGirl.build :listserv_content_metric, listserv_content_id: listserv_content.id
      expect(listserv_content_metric).to be_valid
    end
  end
end
