class AnnotationReport < ActiveRecord::Base

  belongs_to :content
  has_many :annotations

  attr_accessible :content_id, :name, :description

  def metrics
    report = {
      :recognized => 0,
      :distinct_recognized => 0,
      :correct_recognized => 0,
      :distinct_correct_recognized => 0,
      :trusted => 0,
      :distinct_trusted => 0,
      :correct_trusted => 0,
      :distinct_correct_trusted => 0,
      :lookup_edges => 0,
      :distinct_lookup_edges => 0
    }

    seen_recognized = Set.new
    seen_trusted = Set.new
    seen_lookups = Set.new
    annotations.each do |annotation|
      correct = annotation.status == "accepted"
      if annotation.lookup_class.blank?
        if !annotation.recognized_class.blank?
            seen = seen_recognized.include? annotation.annotated_string
            seen_recognized.add annotation.annotated_string
            report[:recognized] += 1
            if !seen
              report[:distinct_recognized] += 1
              if correct
                report[:distinct_correct_recognized] += 1
              end
            end
            if correct
              report[:correct_recognized] += 1
            end
        end
      else
        seen = seen_trusted.include? annotation.annotated_string
        seen_trusted.add annotation.annotated_string
        report[:trusted] += 1
        if !seen
          report[:distinct_trusted] += 1
          if correct
            report[:distinct_correct_trusted] += 1
          end
        end
        if correct
          report[:correct_trusted] += 1
        end

        edges = annotation.edges
        if !edges.nil?
          report[:lookup_edges] += edges.length

          seen_lookup = seen_lookups.include? annotation.lookup_class
          seen_lookups.add annotation.lookup_class
          if !seen_lookup
            report[:distinct_lookup_edges] += edges.length
          end
        end

      end
    end 

    report
  end
end
