require 'spec_helper'

describe Content do

  describe "new from import job" do
    before do
      # base_data is not enough to pass quarantine
      # need to add pubdate, source to validate
      @base_data = {
        "title" => "This is a Title",
        "subtitle" => "Subtitle",
        "page" => "a3",
        "source_content_id" => "1234567"
      }
    end
        
    it "should create a new content with basic data passed by hash" do
      Content.count.should== 0
      content = Content.create_from_import_job(@base_data)
      Content.count.should== 1
    end

    it "should mark non-valid corpus entries as quarantined" do
      content = Content.create_from_import_job(@base_data)
      content.quarantine.should be_true
    end

    it "should leave valid corpus entries as unquarantined" do
      @base_data["pubdate"] = Time.now
      p = FactoryGirl.create(:publication)
      @base_data["source_id"] = p.id
      content = Content.create_from_import_job(@base_data)
      content.quarantine.should== false
    end

    it "should overwrite any existing content with the same publication and source_content_id" do
      p = FactoryGirl.create(:publication)
      @base_data["source_id"] = p.id
      content_orig = Content.create_from_import_job(@base_data)
      orig_id = content_orig.id
      @new_data = {
        "title" => "Different Title",
        "source_content_id" => @base_data["source_content_id"],
        "source_id" => @base_data["source_id"]
      }
      new_content = Content.create_from_import_job(@new_data)
      new_content.id.should== orig_id
      Content.count.should== 1
      db_content = Content.all.first
      db_content.title.should== "Different Title"
    end

    it "should overwrite any existing content with the same guid" do
      p = FactoryGirl.create(:publication)
      @base_data["source_id"] = p.id
      c1 = Content.create_from_import_job(@base_data)
      orig_id = c1.id
      @new_data = {
        "title" => "Different Title",
        "source_id" => @base_data["source_id"],
        "guid" => c1.guid
      }
      c2 = Content.create_from_import_job(@base_data)
      Content.count.should== 1
      Content.first.id.should== orig_id
    end

    # check source logic
    it "should create source if source is provided and it doesn't match existing publications" do
      @base_data["source"] = "Test Publication"
      content = Content.create_from_import_job(@base_data)
      content.source.name.should== "Test Publication"
    end
    it "should match an existing publication if source matches publication name" do
      pub = FactoryGirl.create(:publication)
      @base_data["source"] = pub.name
      content = Content.create_from_import_job(@base_data)
      content.source.should== pub
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
    it "should assign the appropriate data to the newly created issue" do
      @base_data["edition"] = "Holiday Edition"
      @base_data["source"] = "Test Pub"
      content = Content.create_from_import_job(@base_data)
      content.issue.issue_edition.should== "Holiday Edition"
      content.issue.publication_date.should== content.pubdate
      content.issue.publication.should== content.source
    end
    it "should match existing issues by publication and name" do
      pubdate = Time.now
      issue_1 = FactoryGirl.create(:issue, publication_date: pubdate) # matching pub
      issue_2 = FactoryGirl.create(:issue, issue_edition: issue_1.issue_edition) #matching name, different pub
      @base_data["edition"] = issue_1.issue_edition
      @base_data["source"] = issue_1.publication.name
      @base_data["pubdate"] = pubdate
      
      content = Content.create_from_import_job(@base_data)
      content.issue.should== issue_1
    end

    it "should set the import_record_id of content if provided" do
      record = FactoryGirl.create(:import_record)
      content = Content.create_from_import_job(@base_data, record.import_job)
      content.import_record.should== record
    end

    it "should create an image record and copy the file to our CDN if 'image' is provided" do
      @base_data["image"] = "https://www.google.com/images/srpr/logo11w.png"
      c = Content.create_from_import_job(@base_data)
      c.images.count.should == 1
      image = c.images.first
      image.image.url.present?.should be_true
      image.source_url.should== "https://www.google.com/images/srpr/logo11w.png"
    end

  end

  describe "set guid if not present" do
    it "should set the guid of new content that has none" do
      content = FactoryGirl.create(:content)
      content.guid.should== "#{content.title.gsub(" ", "_").gsub("/", "-")}-#{content.pubdate.strftime("%Y-%m-%d")}"
    end
    it "should not overwrite the guid of new content that has a guid" do
      content = FactoryGirl.create(:content, guid: "Test-Guid")
      content.guid.should== "Test-Guid"
    end
  end
    

  describe "export to xml" do
    before do
      @content = FactoryGirl.create(:content)
    end
    after do
      # clean up output folder
      system("rm -rf #{Figaro.env.content_export_path}/*")
    end


    # fun note: we can assume certain attributes are present
    # after this test because quarantining guarantees that
    # those attributes are present, and export_to_xml doesn't work
    # and returns false if quarantine is true
    it "should not allow export of quarantined contents" do
      @content.quarantine = true
      # returns false if it fails to run
      @content.export_to_xml.should== false
    end

    it "should write xml and content to local corpus" do
      # output base dir defined by Figaro
      @content.export_to_xml
      File.exists?("#{@content.export_path}/#{@content.guid}.xml").should be_true
      File.exists?("#{@content.export_path}/#{@content.guid}.html").should be_true
      # check the content file includes the content
      file_content = ""
      File.open "#{@content.export_path}/#{@content.guid}.html", "r" do |f|
        f.each_line do |line|
          file_content << line
        end
      end
      file_content.include?(@content.content).should be_true

      # check the xml file includes some basic stuff like title
      log = Logger.new("#{Rails.root}/log/tests.log")
      log.debug "quarantine: #{@content.quarantine}"
      xml_content = File.open("#{@content.export_path}/#{@content.guid}.xml", "r").readlines.join()
      log.debug "path: #{@content.export_path}"
      log.debug "guid: #{@content.guid}"
      log.debug "full path: #{@content.export_path}/#{@content.guid}.xml"
      log.debug "xml_content: #{xml_content}"
      xml_content.include?(@content.title).should be_true
      xml_content.include?(@content.pubdate.strftime(Content::PUBDATE_OUTPUT_FORMAT)).should be_true
    end
  end

  describe "to kim xml" do
    before do
      @content = FactoryGirl.create(:content)
      @xml = @content.to_kim_xml
    end

    it "should contain all the attributes aside from associations" do
      @content.attributes.each do |k, v|
        if /[[:alpha:]]*_id/.match(k).nil?
          unless v.nil?
            # account for pubdate / timestamp formatting
            if k == "pubdate" or k == "timestamp"
              @xml.include?("<#{k}>#{v.strftime(Content::PUBDATE_OUTPUT_FORMAT)}</#{k}>").should be_true
            else
              @xml.include?("<#{k}>#{v}</#{k}>").should be_true
            end
          else
            @xml.include?("<#{k}/>").should be_true
          end
        end
      end
    end

    it "should contain the associations" do
      @xml.include?("<issue").should be_true
      @xml.include?("<publication").should be_true
      @xml.include?("<location").should be_true
      @xml.include?(@content.issue.issue_edition).should be_true if @content.issue.present?
      @xml.include?(@content.source.name).should be_true if @content.source.present?
      @xml.include?(@content.location.city).should be_true if @content.location.present?
    end
  end

  describe "to new xml" do
    before do
      @content = FactoryGirl.create(:content)
      @xml = @content.to_new_xml
    end

    it "should contain all the attributes as feature name/value pairs" do
      @content.attributes.each do |k, v|
        unless ["id", "created_at", "updated_at", "quarantine", "published", "content"].include? k or /.+id/.match(k)
          # just checking with closing tags so we don't have to deal
          # with exact formatting of opening tag and attributes
          @xml.include?("#{k.upcase}</tns:name>").should be_true
          unless v.nil?
            # account for pubdate / timestamp formatting
            if k == "pubdate" or k == "timestamp"
              @xml.include?("#{v.strftime(Content::PUBDATE_OUTPUT_FORMAT)}</tns:value>").should be_true
            # account for cdata
            elsif k == "authoremail" or k == "authors"
              @xml.include?("#{v}]]></tns:value>").should be_true
            else
              @xml.include?("#{v}</tns:value>").should be_true
            end
          end
        end
      end
    end

    it "should contain document part with content" do
      # note the brackets at the end are closing CDATA
      @xml.include?("#{@content.content}]]></tns:content>").should be_true
    end 
  end

end
