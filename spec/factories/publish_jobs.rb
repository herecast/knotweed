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

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :publish_job do
    frequency 0
    publish_method Content::EXPORT_TO_XML

    after(:build) do |pj|
      pj.query_params[:repository_id] = FactoryGirl.create(:repository).id
    end
  end
end
