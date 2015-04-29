module ContentsLocationsHelper

  def self.do_insert_ids(content_id, location_id)
    sql = 'INSERT INTO contents_locations (content_id, location_id, created_at, updated_at) VALUES (' + content_id.to_s + ',' + location_id.to_s + ', now(), now())'
    ActiveRecord::Base.connection.execute(sql)
  end

  def self.content_location_exists?(content_id, location_id)
    found = false
    sql = 'SELECT * FROM contents_locations WHERE content_id=' + content_id.to_s + ' AND location_id=' + location_id.to_s
    result = ActiveRecord::Base.connection.execute(sql)

    result.each do |row|
      found = true
    end

    found
  end

  def self.count_instances(content_id, location_id)
    sql = 'SELECT * FROM contents_locations WHERE content_id=' + content_id.to_s + ' AND location_id=' + location_id.to_s
    result = ActiveRecord::Base.connection.execute(sql)

    count = 0
    result.each do |row|
      count += 1
    end

    count
  end
end