class Annotation < ActiveRecord::Base

  belongs_to :annotation_report

  attr_accessible :accepted, :annotation_id, :annotation_report_id

  def status
    if accepted == true
      "accepted"
    elsif accepted == false
      "rejected"
    else
      "pending"
    end
  end
end
