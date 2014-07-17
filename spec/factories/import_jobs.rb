# == Schema Information
#
# Table name: import_jobs
#
#  id              :integer          not null, primary key
#  parser_id       :integer
#  name            :string(255)
#  config          :text
#  source_path     :string(255)
#  type            :string(255)
#  organization_id :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  status          :string(255)
#  frequency       :integer          default(0)
#  archive         :boolean          default(FALSE), not null
#  content_set_id  :integer
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :import_job do
    name "MyString"
    source_path "#{Rails.root}/lib/parsers/test/input"
    organization
  end
end
