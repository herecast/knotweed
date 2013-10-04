require 'spec_helper'

describe ImportJob do

  describe "validation" do
    it "should ensure parser belongs to same organization or is universal" do
      @org1 = FactoryGirl.create(:organization)
      @org2 = FactoryGirl.create(:organization)
      @parser = FactoryGirl.create(:parser, organization: @org1)
      @univ_parser = FactoryGirl.create(:parser, organization: nil)
      FactoryGirl.build(:import_job, organization: @org2, parser: @parser).should_not be_valid
      FactoryGirl.build(:import_job, organization: @org2, parser: @univ_parser).should be_valid
      FactoryGirl.build(:import_job, organization: @org1, parser: @parser).should be_valid
    end
  end

  describe "perform job" do
    before do
      # note we need sufficient entries in the config hash here for the 
      # output to validate.
      @config = { "timestamp" => "2011-06-07T12:25:00", "guid" => "100", "other_param" => "hello", "pubdate" => "2011-06-07T12:25:00",
                  "source" => "not empty", "title" => "not empty"}
      @parser = FactoryGirl.create(:parser, filename: "parser_that_outputs_config.rb")
      @job = FactoryGirl.create(:import_job, parser: @parser, config: @config.to_yaml)
      # run job via delayed_job hooks (even though delayed_job doesnt run in tests)
      @job.enqueue_job
      # another job whose output fails validation
      @config2 = { "guid" => "101", "other_param" => "hello" }
      @job2 = FactoryGirl.create(:import_job, parser: @parser, config: @config2.to_yaml)
      @job2.enqueue_job
    end

    it "should succeed and set status to success" do
      # confirm DJ thinks job succeeded
      @job.status.should== "success"
    end

    it "should create directory structure for output files" do 
      job_base = @job.job_output_folder
      Dir.exists?("#{Figaro.env.import_job_output_path}/#{job_base}").should be_true
      Find.find(@job.source_path) do |path|
        if FileTest.directory?(path)
          next
        else
          base_path = "#{Figaro.env.import_job_output_path}/#{job_base}/#{File.basename(path, ".*")}"
          Dir.exists?(base_path).should be_true
          month = @config["timestamp"][5..6]
          Dir.exists?("#{base_path}/#{month}")
        end
      end
    end

    it "should output the config provided to the appropriate file" do
      Find.find(@job.source_path) do |path|
        if FileTest.directory?(path)
          next
        else
          file_path = "#{Figaro.env.import_job_output_path}/#{@job.job_output_folder}/#{File.basename(path, ".*")}/#{@config['timestamp'][5..6]}"
          contains_param = false
          File.open("#{file_path}/#{@config["guid"]}.xml", "r") do |f|
            f.each_line do |line|
              if line.include? @config["other_param"]
                contains_param = true
              end
            end
          end
          contains_param.should be_true
        end
      end
    end

    it "should recognize non-validating xml and quarantine those entries in another folder" do 
      base = "#{Figaro.env.import_job_output_path}/#{@job2.job_output_folder}/quarantine"
      Dir.exists?(base).should be_true
      Find.find(@job2.source_path) do |path|
        if FileTest.directory? path
          next
        else
          file_base = base + "/#{File.basename(path, ".*")}/no-month"
          Dir.exists?(file_base).should be_true
          contains_param = false
          File.open("#{file_base}/#{@config2["guid"]}.xml", 'r') do |f|
            f.each_line do |line|
              if line.include? @config2["other_param"]
                contains_param =true
              end
            end
          end
          contains_param.should be_true
        end
      end
    end


    after do
      # clean up folder
      system("rm -rf #{Figaro.env.import_job_output_path}/*")
    end
  end

end
