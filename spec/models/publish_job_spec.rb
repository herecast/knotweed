# == Schema Information
#
# Table name: publish_jobs
#
#  id              :integer          not null, primary key
#  query_params    :text
#  organization_id :integer
#  status          :string(255)
#  frequency       :integer          default(0)
#  publish_method  :string(255)
#  archive         :boolean          default(FALSE)
#  error           :string(255)
#  name            :string(255)
#  description     :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  file_archive    :text
#  run_at          :datetime
#

require 'spec_helper'

describe PublishJob, :type => :model do
  it_behaves_like :scheduled_job

  describe "validations" do
    describe '#repository_present' do
      before do
        @publish_job = FactoryGirl.build :publish_job
        @publish_job.query_params[:repository_id] = nil
      end

      context "when repository_id is not present" do
        it "invalidates the publish job" do
          expect(@publish_job.valid?).to be false
        end
      end
    end
  end

  describe "contents count" do
    before do
      @organization = FactoryGirl.create(:organization)
      FactoryGirl.create_list(:content, 3, organization: @organization)
      FactoryGirl.create_list(:content, 5)
      @job = FactoryGirl.create(:publish_job)
      @repo = FactoryGirl.create(:repository)
      @content_category = FactoryGirl.create :content_category
    end

    it "should return the total number of contents when no query provided" do
      expect(@job.contents_count).to eq(Content.count)
    end

    it "should allow querying by content category id" do
      @job.query_params[:content_category_id] = [@content_category.id]
      @job.save!
      expect(@job.contents_count).to eq(0)
      Content.last.update_attribute :content_category_id, @content_category.id
      expect(@job.contents_count).to eq(1)
    end

    it "should return the correct number of matching contents" do
      @job.query_params[:organization_id] = [@organization.id]
      @job.save!
      expect(@job.contents_count).to eq(Content.where(organization_id: @organization.id).count)
    end

    it "should return only the ids listed if any ids are in the query" do
      @job.query_params[:organization_id] = [@organization.id]
      @job.save!
      expect(@job.contents_count).to be > 1
      @job.query_params[:ids] = "#{Content.last.id}"
      @job.save!
      expect(@job.contents_count).to eq(1)
    end

    it "should return only the contents already published to the specified repo" do
      @job.query_params[:repository_id] = @repo.id
      @job.query_params[:published] = "true"
      @job.save!
      contents = FactoryGirl.create_list(:content, 3)
      @repo.contents << contents
      expect(@job.contents_count).to eq(3)
    end

    it "should return all contents matching the query that are not published to the specified repo when published is false" do
      @job.query_params[:repository_id] = @repo.id
      @job.query_params[:published] = "false"
      @job.save!
      expect(@job.contents_count).to eq(Content.count - @repo.contents.count)
    end
  end

  describe "perform job" do
    context "that outputs files" do
      before do
        @mail_count = ActionMailer::Base.deliveries.count
        @job = FactoryGirl.create(:publish_job, publish_method: Content::EXPORT_TO_XML)
        FactoryGirl.create_list(:content, 3)
        user = FactoryGirl.create(:user)
        @job.notifyees << user
        @job.enqueue_job
        successes, failures = Delayed::Worker.new(:max_priority => nil,
          :min_priority => nil,
          :quiet => false,
          :queues => ["imports", "publishing"]).work_off
      end
      after do
        #clean up output folder
        system("rm -rf #{Content::TMP_EXPORT_PATH}/*")
        FileUtils.rm_rf(File.join("public", "exports"))
      end

      it "should succeed and set status to success" do
        job = PublishJob.find(@job.id)
        expect(job.status).to eq("success")
      end

      it "should publish the contents via desired method (export to xml)" do
        c = Content.first
        expect(File.exists?("#{c.export_path}/#{c.guid}.xml")).to be_truthy
        expect(File.exists?("#{c.export_path}/#{c.guid}.html")).to be_truthy
      end

      it "should create a publish record attached to the job" do
        expect(PublishRecord.count).to eq(1)
        expect(PublishRecord.first.publish_job).to eq(@job)
      end

      it "should assign any contents published to the attached publish record" do
        record = PublishRecord.first
        expect(record.contents.count).to eq(Content.count)
      end

      it "should create a zip archive" do
        expect(Dir["public/exports/*.zip"].length).to eq(1)
      end

      it "should generate a file ready email" do
        expect(ActionMailer::Base.deliveries.count).to eq(@mail_count + 1)
      end
    end
  end

  describe '#last_run_at' do
    before do
      @publish_job = FactoryGirl.create :publish_job
      @publish_record = FactoryGirl.create(:publish_record)
    end

    it "returns created_at from last publish record" do
      allow(@publish_job).to receive(:last_publish_record) { @publish_record }
      expect(@publish_job.last_run_at.to_s).to eq @publish_record.created_at.to_s
    end
  end
end
