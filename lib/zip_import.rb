class ZipImport

  def self.call
    parsed_file = CSV.read("./zips.csv", { col_sep: "\t" })
    
    parsed_file[1..-1].each do |zip_info|
      location = Location.nearest_to_coords(
        latitude: zip_info[-2], longitude: zip_info[-1]
      )[0]

      unless location.zip.present?
        location.update_attribute(:zip, zip_info[0])
      end
    end
  end
end