class ImportJob < ActiveRecord::Base
  belongs_to :organization
  belongs_to :parser
  
  validates_presence_of :organization
  
  attr_accessible :config, :last_run_at, :name, :parser_id, :source_path, :type, :organization_id
end
