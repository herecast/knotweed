# frozen_string_literal: true

namespace :images do
  task copy_to_new_path: :environment do
    connection = Fog::Storage.new(
      provider: 'AWS',
      aws_access_key_id: Figaro.env.aws_access_key_id,
      aws_secret_access_key: Figaro.env.aws_secret_access_key
    )
    bucket = 'knotweed'
    Image.all.each do |i|
      original_path = "uploads/#{i.class.to_s.underscore}/#{i.id}/#{i.image.file.filename}"
      new_path = i.image.path.to_s

      begin
        connection.copy_object(bucket, original_path, bucket, new_path)
        puts "just copied #{original_path}"
      rescue StandardError
        puts "failed to copy #{original_path}"
      end
    end
  end

  task reprocess_all: :environment do
    progress_log_file = Rails.root.join('log', 'image-reprocess-progress.log')
    FileUtils.touch(progress_log_file)
    processed_ids = File.readlines(progress_log_file).map(&:to_i)

    query = Image.order('id DESC')
    query = query.where('id NOT IN (?)', processed_ids) if processed_ids.any?

    to_process = query.pluck(:id)

    File.open(progress_log_file, 'a') do |log|
      to_process.in_groups(100, false).each do |group|
        query.where(id: group).each do |image|
          # https://github.com/carrierwaveuploader/carrierwave/wiki/How-to:-Recreate-and-reprocess-your-files-stored-on-fog
          # image.process_image_upload = true
          next unless image.image.file.exists?

          begin
            image.image.cache_stored_file!
            image.image.retrieve_from_cache!(image.image.cache_name)
            image.image.recreate_versions!
            image.save!
            log.puts image.id
            processed_ids << image.id
            puts "Processed #{image.url}"
          rescue CarrierWave::IntegrityError => e
            puts e.message
            next
          end
        end
      end
    end
  end

  task ensure_single_images_are_primary: :environment do
    content_ids = Content.joins(:images).group('contents.id').having('COUNT(images.id) = 1').pluck('contents.id')
    images = Image.where(imageable_type: 'Content', imageable_id: content_ids, primary: false)
    puts "Updating #{images.count} images to primary"
    Image.where(imageable_type: 'Content', imageable_id: content_ids, primary: false).update_all(primary: true)
  end
end
