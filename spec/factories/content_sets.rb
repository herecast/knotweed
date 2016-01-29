# == Schema Information
#
# Table name: content_sets
#
#  id                    :integer          not null, primary key
#  import_method         :string(255)
#  import_method_details :text
#  organization_id       :integer
#  name                  :string(255)
#  description           :text
#  notes                 :text
#  status                :string(255)
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  start_date            :date
#  end_date              :date
#  ongoing               :boolean
#  format                :string(255)
#  publishing_frequency  :string(255)
#  developer_notes       :text
#  import_priority       :integer          default(1)
#  import_url_path       :string(255)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :content_set do
    organization
    name "MyString"
    description "MyText"
    notes "MyText"
    status ContentSet::STATUSES[0]
    format ContentSet::FORMATS[0]
    import_method ContentSet::IMPORT_METHODS[0]
  end
end
