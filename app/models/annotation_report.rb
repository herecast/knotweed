class AnnotationReport < ActiveRecord::Base

  belongs_to :content
  has_many :annotations

  attr_accessible :content_id, :name, :description

  def metrics
    report = {
      "recognized" => 0,
      "distinct_recognized" => 0,
      "correct_recognized" => 0,
      "distinct_correct_recognized" => 0,
      "trusted" => 0,
      "distinct_trusted" => 0,
      "correct_trusted" => 0,
      "distinct_correct_trusted" => 0
    }

    seen_annotations = Set.new
    annotations.each do |annotation|
      seen = seen_annotations.include? annotation.annotated_string
      correct = annotation.status == "accepted"
      seen_annotations.add annotation.annotated_string
      if annotation.lookup_class.blank?
        if !annotation.recognized_class.blank?
            report["recognized"] += 1
            if !seen
              report["distinct_recognized"] += 1
              if correct
                report["distinct_correct_recognized"] += 1
              end
            end
            if correct
              report["correct_recognized"] += 1
            end
        end
      else
        report["trusted"] += 1
        if !seen
          report["distinct_trusted"] += 1
          if correct
            report["distinct_correct_trusted"] += 1
          end
        end
        if correct
          report["correct_trusted"] += 1
        end
      end
    end 

    report
  end
end
