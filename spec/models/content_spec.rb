require 'spec_helper'

describe Content do

  describe "new from import job" do
    before do
      # base_data is not enough to pass quarantine
      # need to add pubdate, source to validate
      @base_data = {
        "title" => "This is a Title",
        "subtitle" => "Subtitle",
        "page" => "a3"
      }
    end
        
    it "should create a new content with basic data passed by hash" do
      Content.count.should== 0
      content = Content.create_from_import_job(@base_data)
      Content.count.should== 1
    end

    it "should mark non-valid corpus entries as quarantined" do
      content = Content.create_from_import_job(@base_data)
      content.quarantine.should== true
    end

    it "should leave valid corpus entries as unquarantined" do
      @base_data["pubdate"] = Time.now
      p = FactoryGirl.create(:publication)
      @base_data["contentsource_id"] = p.id
      content = Content.create_from_import_job(@base_data)
      content.quarantine.should== false
    end

    # check contentsource logic
    it "should create contentsource if source is provided and it doesn't match existing publications" do
      @base_data["source"] = "Test Publication"
      content = Content.create_from_import_job(@base_data)
      content.contentsource.name.should== "Test Publication"
    end
    it "should match an existing publication if source matches publication name" do
      pub = FactoryGirl.create(:publication)
      @base_data["source"] = pub.name
      content = Content.create_from_import_job(@base_data)
      content.contentsource.should== pub
    end

    # check location logic
    it "should create a new location if none is found" do
      @base_data["location"] = "Test Location"
      content = Content.create_from_import_job(@base_data)
      content.location.city.should== "Test Location"
    end
    it "should match existing locations by city" do
      loc = FactoryGirl.create(:location)
      @base_data["location"] = loc.city
      content = Content.create_from_import_job(@base_data)
      content.location.city.should== loc.city
    end
    
    # check issue/edition logic
    it "should create a new edition if none is found" do
      @base_data["edition"] = "Holiday Edition"
      content = Content.create_from_import_job(@base_data)
      content.issue.issue_edition.should== "Holiday Edition"
    end
    it "should assign the appropriate publication to the new edition if content has pub" do
      @base_data["edition"] = "Holiday Edition"
      @base_data["source"] = "Test Pub"
      content = Content.create_from_import_job(@base_data)
      content.issue.issue_edition.should== "Holiday Edition"
      content.issue.publication.should== content.contentsource
    end
    it "should match existing issues by publication and name" do
      issue_1 = FactoryGirl.create(:issue) # matching pub
      issue_2 = FactoryGirl.create(:issue, issue_edition: issue_1.issue_edition) #matching name, different pub
      @base_data["edition"] = issue_1.issue_edition
      @base_data["source"] = issue_1.publication.name
      content = Content.create_from_import_job(@base_data)
      content.issue.should== issue_1
    end

  end
end
