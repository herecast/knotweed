class ContentDspSerializer

  PUBDATE_OUTPUT_FORMAT = "%Y-%m-%dT%H:%M:%S"

  attr_reader :content

  # @param content [Content] object to be serialized
  def initialize(content)
    @content = content
  end

  # generates DSP compatible XML from a content record of unknown type
  # (as of now, Content)
  #
  # @param include_tags [Boolean] determines whether or not to strip HTML
  #   tags from the content being sent to the DSP
  # @return [String] XML output string for the DSP
  def to_xml(include_tags=false)
    xml = ::Builder::XmlMarkup.new
    xml.instruct!
    xml.tag!("tns:document", "xmlns:tns"=>"http://www.ontotext.com/DocumentSchema", "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance", "id" => content.document_uri) do |f|
      f.tag!("tns:document-parts") do |g|
        f.tag!("tns:feature-set") do |g|
          content.feature_set.each do |k, v|
            g.tag!("tns:feature") do |h|
              if ["issue_id", "organization_id", "import_location_id", "parent_id"].include? k
                if k == "issue_id" and content.issue.present?
                  key, value = "ISSUE", content.issue.issue_edition
                elsif k == "organization_id" and content.organization.present?
                  key, value = "SOURCE", content.organization.name
                elsif k == "import_location_id" and content.import_location.present?
                  if content.import_location.status == ImportLocation::STATUS_GOOD
                    key, value = "LOCATION", content.import_location.city
                  end
                elsif k == "parent_id" and content.parent.present?
                  key, value = "PARENT", "#{Content::BASE_URI}/#{v}"
                end
              else
                key = k.upcase
                if ["PUBDATE", "TIMESTAMP", "START_DATE", "END_DATE"].include? key and v.present?
                  value = v.strftime(PUBDATE_OUTPUT_FORMAT)
                else
                  value = v
                end
              end
              unless key == "CONTENT"
                h.tag!("tns:name", key, "type"=>"xs:string")
                if key == "AUTHORS" or key == "AUTHOREMAIL"
                  g.tag!("tns:value", "type"=>"xs:string") do |i|
                    if value.present?
                      i.cdata!(value)
                    end
                  end
                else
                  g.tag!("tns:value", value, "type"=>"xs:string")
                end
              end
            end
          end
          if content.try(:images).present? or content.try(:organization).try(:images).present?
            g.tag!("tns:feature") do |h|
              h.tag!("tns:name", "IMAGE", "type"=>"xs:string")
              if content.images.present?
                g.tag!("tns:value", content.primary_image.image.url, "type"=>"xs:string")
              elsif content.organization.images.present?
                g.tag!("tns:value", content.organization.images.first.image.url, "type"=>"xs:string")
              end
            end
          end
            
        end
        g.tag!("tns:document-part", "part"=>"BODY", "id"=>"1") do |h|
          h.tag!("tns:content") do |i|
            i.cdata!(content.publish_content(include_tags))
          end
        end
      end
      
    end
    xml.target!
  end
end
