require 'spec_helper'

describe ImportJob do

  describe "after create" do
    
    it "should schedule a delayed job" do
      job_count = Delayed::Job.count
      job = FactoryGirl.create(:import_job)
      Delayed::Job.count.should== job_count + 1
    end
    
  end

end
