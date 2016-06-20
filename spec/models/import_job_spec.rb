# == Schema Information
#
# Table name: import_jobs
#
#  id                    :integer          not null, primary key
#  parser_id             :integer
#  name                  :string(255)
#  config                :text
#  source_path           :string(255)
#  job_type              :string(255)
#  organization_id       :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  status                :string(255)
#  frequency             :integer          default(0)
#  archive               :boolean          default(FALSE), not null
#  content_set_id        :integer
#  run_at                :datetime
#  stop_loop             :boolean          default(TRUE)
#  automatically_publish :boolean          default(FALSE)
#  repository_id         :integer
#  publish_method        :string(255)
#

require 'spec_helper'

describe ImportJob, :type => :model do

  it_behaves_like :scheduled_job

  describe "perform job" do
    before do
      prerender_cache_stub
      # note we need sufficient entries in the config hash here for the
      # output to validate.
      @config = { "timestamp" => "2011-06-07T12:25:00", "guid" => "100", "other_param" => "hello", "pubdate" => "2011-06-07T12:25:00",
                  "source" => "not empty", "title" => "      not empty and with whitespace  ",
                  "content" => "<p> </p> <p> </p> Content begins here" }
      @parser = FactoryGirl.create(:parser, filename: "test/parser_that_outputs_config.rb")
      @consumer_apps = FactoryGirl.create_list :consumer_app, 2
      @job = FactoryGirl.create(:import_job, parser: @parser, config: @config, consumer_apps: @consumer_apps)
      # run job via delayed_job hooks (even though delayed_job doesnt run in tests)
      @job.enqueue_job
      # another job whose output fails validation
      @config2 = { "guid" => "101", "other_param" => "hello" }
      @job2 = FactoryGirl.create(:import_job, parser: @parser, config: @config2)
      @job2.enqueue_job
      successes, failures = Delayed::Worker.new(:max_priority => nil,
        :min_priority => nil,
        :quiet => false,
        :queues => ["imports", "publishing"]).work_off
    end

    it "should succeed and set status to success" do
      # confirm DJ thinks job succeeded
      job = ImportJob.find(@job.id)
      expect(job.status).to eq("success")
    end

    it "should create an import record attached to the job" do
      expect(ImportRecord.count).to eq(2)
      expect(ImportRecord.where(import_job_id: @job.id).count).to eq(1)
      record = ImportRecord.where(import_job_id: @job.id).first
      expect(@job.last_import_record).to eq(record)
    end

    it "should create a new Content entry" do
      # 2 since we've run two jobs with two different configs here
      # also note that @config["title"] has to be stripped
      # to confirm the import job is stripping all data fields before
      # passing it to Content
      expect(Content.count).to eq(2)
      expect(Content.where(title: @config["title"].strip).count).to eq(1)
      expect(Content.where(timestamp: nil).count).to eq(1)
    end

    it "should strip empty p tags from the beginning of content" do
      c = Content.where(title: @config["title"].strip).first
      expect(c.content.include?("<p> </p>")).to eq(false)
    end

    it "should send a request to prerender recache" do
      expect(WebMock).to have_requested(:post, "http://api.prerender.io/recache").twice
    end

  end

  describe '#set_stop_loop' do
    before do
      @import_job = FactoryGirl.create :import_job, job_type: 'continuous'
    end

    context "when import_job is continuous" do
      it "sets stop_loop to false" do
        @import_job.set_stop_loop
        expect(@import_job.stop_loop).to be false
      end
    end
  end

  describe '#perform' do
    before do
      @parser = FactoryGirl.create :parser
      @import_job = FactoryGirl.create :import_job, parser_id: @parser.id
    end

    context "when import job backing up" do
      it "skips the job" do
        allow(ImportJob).to receive(:backup_start).and_return(Time.current - 10)
        allow(ImportJob).to receive(:backup_end).and_return(Time.current + 10)
        import_record = FactoryGirl.create(:import_record)
        allow(@import_job).to receive(:last_import_record) { import_record }
        log = import_record.log_file
        allow(import_record).to receive(:log_file) { log }

        expect(log).to receive(:info)
        @import_job.perform
      end
    end
  end

  describe '#traverse_input_tree' do
    before do
      @import_job = FactoryGirl.create :import_job, job_type: 'continuous'
      @import_record = FactoryGirl.create :import_record
    end

    context "when continuous and during backup" do
      it "stop_loop becomes false" do
        allow(ImportJob).to receive(:backup_start).and_return(Time.current - 10)
        allow(ImportJob).to receive(:backup_end).and_return(Time.current + 10)
        allow(@import_job).to receive(:last_import_record) { @import_record }
        response = @import_job.traverse_input_tree
        expect(@import_job.stop_loop).to be false
      end
    end
  end

  describe '#reschedule_at' do
    before do
      Timecop.freeze
      @import_job = FactoryGirl.create :import_job
    end
    after { Timecop.return }

    context "when reschedule_at is set" do
      it "returns a set reschedule time" do
        allow_any_instance_of(Figaro::Env).to receive(:reschedule_at).and_return('10')
        response = @import_job.reschedule_at(DateTime.current, 1)
        expect(response.to_s).to eq (DateTime.current + 10.seconds).to_s
      end
    end

    context "when no reschedule_at environmental variable" do
      it "returns a fabricated reschedule time" do
        allow_any_instance_of(Figaro::Env).to receive(:reschedule_at).and_return(nil)
        response = @import_job.reschedule_at(DateTime.current, 1)
        expect(response.to_s).to eq (DateTime.current + 6).to_s
      end
    end
  end

  describe '#import_filter' do
    before do
      @import_job = FactoryGirl.create :import_job
      @content = FactoryGirl.create :content, channel_id: 1
      @event = FactoryGirl.create(:event, channel_id: 1)
      @event_instance = FactoryGirl.create :event_instance, event_id: @event.id
    end

    let(:article) { { 'X-Original-Content-Id' => @content.id } }

    context "when article has content id" do
      it "returns true and reason" do
        response = @import_job.import_filter(article)
        expect(response[0]).to be true
        expect(response[1]).to include 'X-Original-Content-Id'
      end
    end

    let(:instance) { { 'X-Original-Event-Instance-Id' => @event_instance.id } }

    context "when article has instance id" do
      it "returns true and reason" do
        response = @import_job.import_filter(instance)
        expect(response[0]).to be true
        expect(response[1]).to include 'X-Original-Event-Instance-Id'
      end
    end
  end

end
