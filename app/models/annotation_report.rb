require 'csv'

class AnnotationReport < ActiveRecord::Base

  belongs_to :content
  has_many :annotations, dependent: :destroy
  belongs_to :repository

  attr_accessible :content_id, :name, :description, :json_response, :repository_id, :repository
  
  default_scope order('created_at DESC')

  validates_presence_of :repository

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
      :distinct_lookup_edges => 0,
      :correct_lookup_edges => 0,
      :distinct_correct_lookup_edges => 0
    }

    seen_recognized = Set.new
    seen_correct_recognized = Set.new
    seen_trusted = Set.new
    seen_correct_trusted = Set.new
    seen_instances = Set.new
    seen_correct_instances = Set.new

    annotations.each do |annotation|
      correct = annotation.status == "accepted"
      # if is_trusted, we treat as a lookup
      unless annotation.is_trusted
        if !annotation.recognized_class.blank?
            seen = seen_recognized.include? annotation.annotated_string
            seen_recognized.add annotation.annotated_string
            report[:recognized] += 1
            if !seen
              report[:distinct_recognized] += 1
            end
            if correct
              seen = seen_correct_recognized.include? annotation.annotated_string
              seen_correct_recognized.add annotation.annotated_string
              report[:correct_recognized] += 1
              if !seen
                report[:distinct_correct_recognized] += 1
              end
            end
        end
      else
        seen = seen_trusted.include? annotation.annotated_string
        seen_trusted.add annotation.annotated_string
        report[:trusted] += 1
        if !seen
          report[:distinct_trusted] += 1
        end
        if correct
          seen = seen_correct_trusted.include? annotation.annotated_string
          seen_correct_trusted.add annotation.annotated_string
          report[:correct_trusted] += 1
          if !seen
            report[:distinct_correct_trusted] += 1
          end
        end
      end

      edges = annotation.edges
      if edges

        edges = AnnotationReport.filter_edges(edges)
        seen = seen_instances.include? annotation.instance
        seen_instances.add annotation.instance
        report[:lookup_edges] += edges.length
        if !seen
          report[:distinct_lookup_edges] += edges.length
        end
        if correct
          seen = seen_correct_instances.include? annotation.instance
          seen_correct_instances.add annotation.instance
          report[:correct_lookup_edges] += edges.length
          if !seen
            report[:distinct_correct_lookup_edges] += edges.length
          end
        end
      end

    end 

    report
  end

  def self.filter_edges(edges)
    edges.select { |e|
      edge_type = Annotation.parse_uri_for_class e["predicate"]["value"]
      edge_type != "label" && edge_type != "mainLabel"
    }
  end

  def self.csv_report(content_id)

    reports = self.where( content_id: content_id )
    CSV.generate do |csv|

      csv << [
        "Name",
        "Date",
        "Total Recognized",
        "Distinct Recognized",
        "Correct Recognized",
        "Distinct Correct Recognized",
        "Total Lookups",
        "Distinct Lookups",
        "Correct Lookups",
        "Distinct Correct Lookups",
        "Total Additional Edges",
        "Distinct Additional Edges",
        "Correct Additional Edges",
        "Distinct Correct Additional Edges"
      ]

      reports.each { |report| 
        metrics = report.metrics
        csv << [
          report.name,
          report.created_at,
          metrics[:recognized],
          metrics[:distinct_recognized],
          metrics[:correct_recognized],
          metrics[:distinct_correct_recognized],
          metrics[:trusted],
          metrics[:distinct_trusted],
          metrics[:correct_trusted],
          metrics[:distinct_correct_trusted],
          metrics[:lookup_edges],
          metrics[:distinct_lookup_edges],
          metrics[:correct_lookup_edges],
          metrics[:distinct_correct_lookup_edges]
        ]
      }

    end

  end

end
