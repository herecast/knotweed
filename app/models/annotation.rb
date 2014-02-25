class Annotation < ActiveRecord::Base

  belongs_to :annotation_report

  attr_accessible :accepted, :annotation_id, :annotation_report_id
end
