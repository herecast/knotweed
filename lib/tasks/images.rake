namespace :images do

  task :copy_to_new_path => :environment do
    connection = Fog::Storage.new({
      :provider => "AWS",
      :aws_access_key_id => Figaro.env.aws_access_key_id,
      :aws_secret_access_key => Figaro.env.aws_secret_access_key
    })
    bucket = "knotweed"
    Image.all.each do |i|
      original_path = "uploads/#{i.class.to_s.underscore}/#{i.id}/#{i.image.file.filename}"
      new_path = i.image.path.to_s
      
      begin
        connection.copy_object(bucket, original_path, bucket, new_path) 
        puts "just copied #{original_path}"
      rescue
        puts "failed to copy #{original_path}"
      end
        
    end 

  end

end
