# == Schema Information
#
# Table name: contents
#
#  id                       :integer          not null, primary key
#  title                    :string(255)
#  subtitle                 :string(255)
#  authors                  :string(255)
#  raw_content              :text
#  issue_id                 :integer
#  import_location_id       :integer
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  copyright                :string(255)
#  guid                     :string(255)
#  pubdate                  :datetime
#  source_category          :string(255)
#  topics                   :string(255)
#  url                      :string(255)
#  origin                   :string(255)
#  language                 :string(255)
#  page                     :string(255)
#  authoremail              :string(255)
#  publication_id           :integer
#  quarantine               :boolean          default(FALSE)
#  doctype                  :string(255)
#  timestamp                :datetime
#  contentsource            :string(255)
#  import_record_id         :integer
#  source_content_id        :string(255)
#  parent_id                :integer
#  content_category_id      :integer
#  category_reviewed        :boolean          default(FALSE)
#  has_event_calendar       :boolean          default(FALSE)
#  channelized_content_id   :integer
#  published                :boolean          default(FALSE)
#  channel_type             :string(255)
#  channel_id               :integer
#  root_content_category_id :integer
#  delta                    :boolean          default(TRUE), not null
#  created_by               :integer
#  updated_by               :integer
#

require 'spec_helper'

describe Content do

  before { Promotion.any_instance.stub(:update_active_promotions).and_return(true) }

  include_examples 'Auditable', Content

  # I wasn't sure where else to put this test...
  # the content index (app/indices/content_index) uses a
  # condition that needs to be tested to confirm it's working.
  describe 'sphinx index' do
    before do
      @event_cat = FactoryGirl.create :content_category, name: 'event'
      @news_cat = FactoryGirl.create :content_category, name: 'news'
      @in_index_event = FactoryGirl.create :event
      # ensure in_index_event has the event category
      @in_index_event.content.content_category_id = @event_cat.id
      @in_index_event.content.save
      @not_in_index_event = FactoryGirl.create :content, content_category_id: @event_cat.id
    end

    it 'should not include unchannelized event category content' do
      expect(Content.search).to_not include(@not_in_index_event)
    end
    
    it 'should not include unchannelized event category content' do
      expect(Content.search).to include(@in_index_event.content)
    end

  end

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
      c.find_root_parent.should == c
    end
    it "should return the root parent for content" do
      c1 = FactoryGirl.create(:content)
      c2 = FactoryGirl.create(:content, publication: c1.publication, parent: c1)
      c3 = FactoryGirl.create(:content, publication: c1.publication, parent: c2)
      c2.find_root_parent.should == c1
      c3.find_root_parent.should == c1
    end
  end

  describe "get_downstream_thread" do 
    it "should return nil for contents without children" do
      c = FactoryGirl.create(:content)
      c.get_downstream_thread.should == nil
    end

    it "should return a hash representing the full thread below the content" do
      c1 = FactoryGirl.create(:content)
      c2 = FactoryGirl.create(:content, publication: c1.publication, parent: c1)
      c3 = FactoryGirl.create(:content, publication: c1.publication, parent: c1)
      c4 = FactoryGirl.create(:content, publication: c1.publication, parent: c3)
      c1.get_downstream_thread.should == {
        c2.id => nil, c3.id => { 
          c4.id => nil 
        } 
      }
    end
  end

  describe "mark_quarantined" do
    before do
      @content = FactoryGirl.create(:content)
    end

    it "should leave valid content unquarantined" do
      @content.quarantine.should== false
    end
    
    it "should mark it quarantined if sanitized_content is empty" do
      @content.raw_content = "<br/>"
      @content.save
      @content.reload
      @content.quarantine.should== true
    end

  end

  describe "mark_published association callback" do
    before do
      @prod_repo = FactoryGirl.create(:repository, id: Repository::PRODUCTION_REPOSITORY_ID)
      @non_prod_repo = FactoryGirl.create(:repository)
      @content = FactoryGirl.create(:content)
    end

    it "should not mark content published when added to a non-production repository" do
      @content.repositories << @non_prod_repo
      @content.reload
      @content.published.should eq(false)
    end

    it "should mark content published when added to prod repo" do
      @content.repositories << @prod_repo
      @content.reload
      @content.published.should eq(true)
    end
  end

  describe "publish_content" do
    before do
      @content = FactoryGirl.create(:content)
    end

    it "should return sanitized_content if it has anything in it" do
      @content.publish_content(true).should == @content.sanitized_content
    end

    it "should strip tags from result if include_tags parameter is false" do
      @content.raw_content = "<p>Hello</p>"
      @content.publish_content(false).should == "Hello"
    end

    it "should not strip tags from result if include_tags parameter is true" do
      @content.raw_content = "<p>Hello</p>"
      @content.publish_content(true).include?(@content.raw_content).should == true
    end
  end

  describe "create from import job" do
    before do
      # base_data is not enough to pass quarantine
      # need to add pubdate, publication to validate
      @base_data = {
        "title" => "This is a Title",
        "subtitle" => "Subtitle",
        "page" => "a3",
        "source_content_id" => "1234567"
      }
      google_logo_stub
      google_logo2_stub
      google_logo3_stub
    end

    after do
      FileUtils.rm_rf('./public/content')
    end
        
    it "should create a new content with basic data passed by hash" do
      Content.count.should== 0
      content = Content.create_from_import_job(@base_data)
      Content.count.should== 1
    end

    it "should match publication based on 'source'" do
      publication = FactoryGirl.create(:publication, reverse_publish_email: "test@test.com")
      data = @base_data.merge({
        source: publication.reverse_publish_email,
        source_field: "reverse_publish_email"
      })
      content = Content.create_from_import_job(data)
      content.publication.should == publication
    end

    it "should mark non-valid corpus entries as quarantined" do
      content = Content.create_from_import_job(@base_data)
      content.quarantine.should == true
    end

    it "should leave valid corpus entries as unquarantined" do
      p = FactoryGirl.create(:publication)
      extra_data = @base_data.merge({
        "pubdate" => Time.now,
        "content" => "hello",
        "publication_id" => p.id
      })
      content = Content.create_from_import_job(extra_data)
      content.quarantine.should== false
    end

    it "should correctly identify parent based on in_reply_to" do
      c = FactoryGirl.create(:content, guid: "this-is-a-guid")
      extra_data = @base_data.merge({
        "pubdate" => Time.now,
        "content" => "hello",
        "publication_id" => c.publication.id,
        "in_reply_to" => c.guid
      })
      c2 = Content.create_from_import_job(extra_data)
      c2.parent.should== c
    end

    it "should overwrite any existing content with the same publication and source_content_id" do
      p = FactoryGirl.create(:publication)
      @base_data["publication_id"] = p.id
      content_orig = Content.create_from_import_job(@base_data)
      orig_id = content_orig.id
      @new_data = {
        "title" => "Different Title",
        "source_content_id" => @base_data["source_content_id"],
        "publication_id" => @base_data["publication_id"]
      }
      new_content = Content.create_from_import_job(@new_data)
      new_content.id.should== orig_id
      Content.count.should== 1
      db_content = Content.all.first
      db_content.title.should== "Different Title"
    end



    it "should overwrite any existing content with the same guid" do
      p = FactoryGirl.create(:publication)
      @base_data["publication_id"] = p.id
      c1 = Content.create_from_import_job(@base_data)
      orig_id = c1.id
      @new_data = {
        "title" => "Different Title",
        "publication_id" => @base_data["publication_id"],
        "guid" => c1.guid
      }
      c2 = Content.create_from_import_job(@new_data)
      Content.count.should== 1
      Content.first.id.should== orig_id
    end

    it "should overwrite any content but retain new category if category field is populated " do
      p = FactoryGirl.create(:publication)
      @base_data["publication_id"] = p.id
      c1 = Content.create_from_import_job(@base_data)
      c1.update_attribute :category, "Test Category"
      orig_id = c1.id
      @new_data = {
        "title" => "Different Title",
        "publication_id" => @base_data["publication_id"],
        "guid" => c1.guid
      }
      c2 = Content.create_from_import_job(@new_data)
      Content.count.should== 1
      Content.first.id.should== orig_id
      Content.first.category.should == "Test Category"
    end

    it "should not overwrite any fields not in the REIMPORT_FEATURES whitelist" do
      p = FactoryGirl.create(:publication)
      @base_data["publication_id"] = p.id
      c1 = Content.create_from_import_job(@base_data)
      c1.update_attribute :copyright, "ropycight" #an attribute that is not whitelisted for reimport
      @new_data = {
        "title" => "New Title",
        "publication_id" => @base_data["publication_id"],
        "guid" => c1.guid,
        "copyright" => "different" # an attribute that is not whitelisted
      }
      Content.create_from_import_job(@new_data)
      c1.reload
      c1.title.should == @new_data["title"]
      c1.copyright.should == "ropycight" # original
    end

    # check source logic
    it "should create publication if source is provided and it doesn't match existing publications" do
      @base_data["source"] = "Test Publication"
      content = Content.create_from_import_job(@base_data)
      content.publication.name.should== "Test Publication"
    end
    it "should match an existing publication if source matches publication name and source_field not provided" do
      pub = FactoryGirl.create(:publication)
      @base_data["source"] = pub.name
      content = Content.create_from_import_job(@base_data)
      content.publication.should== pub
    end

    # check location logic
    it "should create a new location if none is found" do
      @base_data["location"] = "Test Location"
      content = Content.create_from_import_job(@base_data)
      content.import_location.city.should== "Test Location"
    end
    it "should match existing locations by city" do
      loc = FactoryGirl.create(:import_location)
      @base_data["location"] = loc.city
      content = Content.create_from_import_job(@base_data)
      content.import_location.city.should== loc.city
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
      content.issue.publication.should== content.publication
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
      image.image.url.present?.should == true
      image.source_url.should== "https://www.google.com/images/srpr/logo11w.png"
    end

    describe 'should handle created_by and updated_by correctly' do

      it 'should set created_by and updated_by correctly for new imported content' do
        # @user created in auditable_shared_examples.rb included using include_examples 'Auditable', Content
        @base_data['user_id'] = @user.id
        c = Content.create_from_import_job(@base_data)
        c.created_by.should == @user
        c.updated_by.should == @user
      end

    end
    # check primary image handling
    describe 'should handle primary image correctly' do
      before do
        @base_data['images'] = [{'image' => 'https://www.google.com/images/srpr/logo11w.png'},
                                {'image' => 'https://www.google.com/images/srpr/logo9w.png'},
                                {'image' => 'https://www.google.com/images/srpr/logo7w.png'}]
      end

      it 'should have a primary image' do
        c = Content.create_from_import_job(@base_data)
        c.images.length.should == @base_data['images'].count
        image = c.primary_image
        image.image.url.present?.should == true
        image.source_url.should== 'https://www.google.com/images/srpr/logo11w.png'
      end

      it 'should have the correct primary image' do #not necessarily the first
        c = Content.create_from_import_job(@base_data)
        c.images.length.should == @base_data['images'].count
        c.primary_image = c.images.last
        c.reload
        image = c.primary_image
        image.image.url.present?.should == true
        image.source_url.should== 'https://www.google.com/images/srpr/logo7w.png'
      end

      it 'should have only one primary image' do
        c = Content.create_from_import_job(@base_data)
        c.images.length.should == @base_data['images'].count
        c.primary_image = c.images.last
        c.images.where(primary: true).count.should == 1
      end
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

  describe "to new xml" do
    before do
      @content = FactoryGirl.create(:content)
      @image1 = FactoryGirl.create(:image)
      @image2 = FactoryGirl.create(:image)
      @xml = @content.to_new_xml(true)
    end

    it "should contain all the attributes as feature name/value pairs" do
      @content.feature_set.each do |k, v|
        unless ["content", "publication_id", "import_location_id", "parent_id", 
                "issue_id", "content_category_id"].include? k
          # just checking with closing tags so we don't have to deal
          # with exact formatting of opening tag and attributes
          @xml.include?("#{k.upcase}</tns:name>").should be_true
          if v.present?
            # account for pubdate / timestamp formatting
            if k == "pubdate" or k == "timestamp"
              @xml.include?("#{v.strftime(Content::PUBDATE_OUTPUT_FORMAT)}</tns:value>").should be_true
            # account for cdata
            elsif k == "authoremail" or k == "authors"
              @xml.include?("#{v}]]></tns:value>").should be_true
            else
              @xml.include?("#{CGI::escapeHTML v}</tns:value>").should be_true
            end
          end
        end
      end
    end

    it "should use the publication's category_override if that is set" do
      @content.publication.update_attribute :category_override, "Test Category"
      @content.to_new_xml.include?("Test Category").should be_true
    end

    it "should use the category-mapping instead of source_category if available" do
      cat = FactoryGirl.create(:category)
      @content.update_attribute :source_category, cat.name
      @content.update_attribute :category, nil
      @content.to_new_xml.include?(cat.channel.name).should be_true
    end

    it "should populate with a publication image if content doesnt have one" do
      @content.publication.images << @image1
      @content.to_new_xml.include?("IMAGE</tns:name").should be_true
    end

    it "should populate with content image if it exists" do
      @content.images << @image2
      @content.to_new_xml.include?("IMAGE</tns:name").should be_true
    end
    it "should contain document part with content" do
      # note the brackets at the end are closing CDATA
      @xml.include?("#{@content.sanitized_content}]]></tns:content>").should be_true
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
        stub_request(:post, "http://#{ENV['ONTOTEXT_API_USERNAME']}:#{ENV['ONTOTEXT_API_PASSWORD']}@#{@repo.dsp_endpoint.sub(/(?:http:\/\/)?(.*)\/?/, '\1')}/processPrePipeline").
          to_return(:status => 200, 
                    :body => File.open('spec/fixtures/pre_pipeline_output.xml', 'r').readlines.join(),
                    :headers => {})
      end

      subject { @content.export_pre_pipeline_xml(@repo) }
      let(:base_path) { "#{@content.export_path}/pre_pipeline/#{@content.guid}" }

      it "should return true for successful export" do
        expect(subject).to be_true
      end

      it "should create xml and html files" do
        subject
        expect(File.exists? "#{base_path}.xml").to be_true
        expect(File.exists? "#{base_path}.html").to be_true
      end

      it "should have a well-formed XML file" do
        subject
        export = File.open("#{base_path}.xml", "r").readlines.join()
        expect(Nokogiri::XML(export) { |config| config.strict }).to_not be_nil
      end
    end
    
    describe "postpipeline xml" do
      before do
        stub_request(:post, "http://#{ENV['ONTOTEXT_API_USERNAME']}:#{ENV['ONTOTEXT_API_PASSWORD']}@#{@repo.dsp_endpoint.sub(/(?:http:\/\/)?(.*)\/?/, '\1')}/processPostPipeline").
          to_return(:status => 200, 
                    :body => File.open('spec/fixtures/post_pipeline_output.xml', 'r').readlines.join(),
                    :headers => {})
      end

      subject { @content.export_post_pipeline_xml(@repo) }
      let(:base_path) { "#{@content.export_path}/post_pipeline/#{@content.guid}" }

      it "should return true for successful export" do
        expect(subject).to be_true
      end

      it "should create xml and html files" do
        subject
        expect(File.exists? "#{base_path}.xml").to be_true
        expect(File.exists? "#{base_path}.html").to be_true
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
          @content.publish("post_to_ontotext", @repo).should == false
          @repo.contents.include?(@content).should == false
        end
      end
    end

  end

  describe "publish_category" do
    before do
      @content = FactoryGirl.create(:content)
    end

    subject { @content.publish_category }

    describe "if publication.category_override is set" do
      it "should return publication.category_override" do
        @content.publication.update_attribute :category_override, "Test Override"
        subject.should== "Test Override"
      end
    end

    describe "with source_category and category set" do
      it "should return category" do
        @content.category = "Test Subtext Category"
        @content.source_category = "Test Source Category"
        subject.should == "Test Subtext Category"
      end
    end

    describe "with only source_category set" do
      before do
        @content.category = nil
        @content.source_category = "Test Source Category"
      end

      describe "if no Category record exists" do
        it "should return the value of source_category" do
          subject.should== @content.source_category
        end

        it "should create a Category record with empty channel_id" do
          subject
          Category.find_by_name(@content.source_category).present?.should== true
        end
      end

      describe "if category exists with mapped channel" do
        it "should return the corresponding channel's name" do
          cat = FactoryGirl.create(:category)
          @content.source_category = cat.name
          subject.should== cat.channel.name
        end
      end
    end

  end

  describe "has_active_promotion?" do
    before do
      @content = FactoryGirl.create(:content)
    end
    after do
      FileUtils.rm_rf('./public/promotion')
    end

    it "should return false if there are no promotions" do
      @content.has_active_promotion?.should == false
    end

    it "should return false if there is a promotion banner but it is inactive" do
      p = FactoryGirl.create :promotion, active: false, content: @content
      promotion_banner = FactoryGirl.create :promotion_banner, promotion: p
      @content.has_active_promotion?.should == false
    end

    it "should return true if there is an active promotion banner attached" do
      p = FactoryGirl.create :promotion, active: true, content: @content
      promotion_banner = FactoryGirl.create :promotion_banner, promotion: p
      @content.has_active_promotion?.should == true
    end

  end

  describe "update_from_repo" do
    before do
      @content = FactoryGirl.create :content, content_category: nil
      @repository = FactoryGirl.create :repository
      @repository.contents << @content
      @new_cat = stub_retrieve_update_fields_from_repo(@content, @repository)
    end

    it "should overwrite @content.category with data from the repository" do
      orig_cat = @content.category
      @content.update_from_repo(@repository)
      @content.category.should_not == orig_cat
      @content.category.should == @new_cat
    end

  end

  describe "category" do
    before do
      @cat = FactoryGirl.create :content_category
      @content = FactoryGirl.create :content, content_category: @cat
    end

    it "should return the name of the attached content category" do
      @content.category.should == @cat.name
    end

  end

  describe "parent_category" do
    before do
      @parent_cat = FactoryGirl.create :content_category
      @cat = FactoryGirl.create :content_category, parent_id: @parent_cat.id
      @content = FactoryGirl.create :content, content_category: @cat
    end
    it "should return the parent category's name" do
      @content.parent_category.should == @parent_cat.name
    end
  end

  describe "externally visible instance method" do
    before do
      @cat = FactoryGirl.create :content_category
      @pub = FactoryGirl.create :publication
    end

    it "should return false if the content category is not in the publication's external_categories" do
      c = FactoryGirl.create :content, publication: @pub
      c.externally_visible.should be_false
    end

    it "should return true if the content's category is in the publication's external categories" do
      c = FactoryGirl.create :content, publication: @pub, content_category: @cat
      @pub.external_categories << @cat
      c.externally_visible.should be_true
    end
  end

  describe "externally visible scope" do
    before do
      # create a bunch of random content
      FactoryGirl.create_list :content, 5
      pub = FactoryGirl.create :publication
      cat = FactoryGirl.create :content_category
      pub.external_categories << cat
      @c = FactoryGirl.create :content, content_category: cat, publication: pub
      @c2 = FactoryGirl.create :content, publication: pub
      @c3 = FactoryGirl.create :content, content_category: cat
    end

    subject { Content.externally_visible } 

    it "should return only the content belonging to its publication's external categories" do
      subject.count.should eq(1)
      subject.should eq([@c])
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

      parsed_emails[0]['source'].include?('Listserv').should == true
      parsed_emails[0]['content_locations'].length.should == 1
      parsed_emails[0]['content_locations'].include?('Norwich,VT').should == true

      content = Content.create_from_import_job(parsed_emails[0])
      Content.count.should== 1

      content.locations.include?(@norwich).should eq(true)
    end

    it "should create lrn locations" do
      eml = Mail.read(@test_files_path+"/lrn.txt")
      parsed_emails = convert_eml_to_hasharray(eml, @config)

      parsed_emails[0]['source'].include?('Listserv').should == true
      parsed_emails[0]['content_locations'].length.should == 2

      content = Content.create_from_import_job(parsed_emails[0])
      Content.count.should== 1

      content.locations.include?(@corinth).should eq(true)

      content.locations.include?(@topsham).should eq(true)

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
      Content.count.should== 1
      content.locations.include?(@upper_valley).should eq(true)
    end

  end

  describe 'get_comment_thread' do
    before do
      @root = FactoryGirl.create :content
    end

    subject { @root.get_comment_thread }

    it 'should return an empty list if content has no children' do
      subject.should eq([])
    end

    it 'should not include any children that are not comment channel' do
      FactoryGirl.create :content, parent_id: @root.id
      subject.should eq([])
    end

    it 'should return content with the transient attribute "tier" set' do
      tier0 = FactoryGirl.create :comment
      tier0.content.update_attribute :parent_id, @root.id
      subject.should eq([tier0.content])
      subject[0].tier.should eq(0)
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
      subject.count.should eq(4)
      tier_counts = []
      subject.each do |com|
        tier_counts[com.tier] ||=0
        tier_counts[com.tier] +=1
      end
      tier_counts[0].should eq(2)
      tier_counts[1].should eq(1)
      tier_counts[2].should eq(1)
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

    it 'should be one post and two entries in contents_location for each listserv' do

      eml = Mail.read(@test_files_path+"/strafford.txt")
      parsed_emails = convert_eml_to_hasharray(eml, @config)
      content = Content.create_from_import_job(parsed_emails[0])
      Content.count.should== 1
      content.locations.include?(@strafford).should eq(true)
      id_1 = content.id

      eml = Mail.read(@test_files_path+"/new_london.txt")
      parsed_emails = convert_eml_to_hasharray(eml, @config)
      content = Content.create_from_import_job(parsed_emails[0])
      Content.count.should== 1
      content.locations.include?(@new_london).should eq(true)
      id_2 = content.id

      id_1.should == id_2
      content.locations.length.should == 2
      content.locations.include?(@new_london).should eq(true)
      content.locations.include?(@strafford).should eq(true)

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
        content.sanitized_content.should eq File.read(output_file).chomp  
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
