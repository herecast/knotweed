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
#  sidekiq_jid           :string
#  next_scheduled_run    :datetime
#

require 'spec_helper'

describe ImportJob, :type => :model do

  it_behaves_like :scheduled_job

  describe '#set_stop_loop' do
    before do
      @import_job = FactoryGirl.create :import_job, job_type: 'continuous'
    end

    context "when import_job is continuous" do
      it "sets stop_loop to false" do
        @import_job.stop_loop = true
        @import_job.set_stop_loop
        expect(@import_job.stop_loop).to be false
      end
    end
  end
end
