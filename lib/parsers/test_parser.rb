require 'find'
require "json"
require "builder"

def parse_data(input_path, output_path)
  Find.find(input_path) do |path|
    json_files = Dir.glob("#{path}/*.json")
    json_files.each do |file_path|
      file = File.open(file_path, "r:UTF-8")
      # base directory name for output
      base = File.basename(file, ".json")
      #read JSON from file into array
      json_array = JSON.parse file.read
      
      json_array.each do |article|
        # replace slashes with dashes in guid
        xml = ::Builder::XmlMarkup.new
        xml.instruct!

        xml.features do |f|
          article.keys.each do |k|
            unless ["imagecaption", "imagecredit", "pub_date", "author"].include? k
              eval("f.#{k} article[k]")
            end
          end

          if article["author"]
            f.authors article["author"]
          end

          if article["imagecaption"] or article["imagecredit"] 
            f.media do |m|
              m.image do |i|
                i.caption article["imagecaption"]
                i.credit article["imagecredit"]
              end
            end
          end
  
          f.pubdate article["pub_date"]
  
        end

        xml_out = xml.target!
        txt_out = ""
        # quick way to generate txt template
        ["title", "subtitle", "author", "contentsource", "content", "correctiondate", "correction"].each do |feature|
          unless article[feature].nil? or article[feature].empty?
            # this adds an extra line below the content
            txt_out << "\n" if feature == "content"
            if feature == "correctiondate"
              txt_out << "\n" << "Correction Date: "
            elsif feature == "correction"
              txt_out << "Correction: "
            end
            txt_out << article[feature] << "\n"
          end
        end

        # directory structure of output
        Dir.mkdir("#{output_path}/#{base}") unless Dir.exists?("#{output_path}/#{base}")
        month = article["timestamp"][5..6]
        Dir.mkdir("#{output_path}/#{base}/#{month}") unless Dir.exists?("#{output_path}/#{base}/#{month}")
        filename = article["guid"].gsub("/", "-").gsub(" ", "_")

        xml_file = File.open("#{output_path}/#{base}/#{month}/#{filename}.xml", "w+:UTF-8")
        xml_file.write xml_out
        txt_file = File.open("#{output_path}/#{base}/#{month}/#{filename}.txt", "w+:UTF-8")
        txt_file.write txt_out
      end
    end
  end
end