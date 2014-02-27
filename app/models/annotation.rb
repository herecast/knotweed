class Annotation < ActiveRecord::Base

  belongs_to :annotation_report

  attr_accessible :accepted, :annotation_id, :annotation_report_id, :startnode, :endnode, :annotation_type,
                  :is_generated, :lookup_class, :token_feature, :recognized_class, :annotated_string,
                  :instance

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
