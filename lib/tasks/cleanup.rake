namespace :cleanup do

  # cleans up listserv emails pulled from the gmail account
  task :gmail_listserv_emails => :environment do

    begin
      org = Organization.find_by_name("ValleyNet Listserv")
    rescue ActiveRecord::RecordNotFound
      puts "ValleyNet Listserv organization not found"
      break
    end

    # these are the identifying phrases of pieces we want to cut out:
    bad_phrases = ["DO NOT REPLY",
      "---------------------------",
      "your friends to subscribe by sending a blank email",
      "received this message as a subscriber",
      "be removed from this list",
      "Upper Valley-wide posts should be sent",
      "list homepage with posting guidelines",
      "discussion list is provided at no cost",
      "over [0-9,]+ \\w+ listserv",
      "more than [0-9,]+ \\w+ listserv",
      "_____________________________",
      "keep it specific to the town",
      "POSTING RULES SUMMARY",
      "Keep the listserv readable",
      "IMPORTANT NOTICE REGARDING THIS ELECTRONIC MESSAGE",
      "This message is intended for the use of the person",
      "moderator \\(\\w+ \\w+\\) can be reached",
      "HOW TO JOIN?",
      "HOW TO POST?",
      "HOW TO REPLY?",
      "HOW TO UNSUBSCRIBE"
      ]


    Content.where(source_id: org.id).find_each(batch_size: 1000) do |c|
      # separate content into pieces based on our inserted
      # delimiter "\n\n"
      content_pieces = c.content.split("\n\n")
      content_pieces.map! do |cp|
        new_val = cp
        bad_phrases.each do |phrase|
          if /#{phrase}/.match cp
            new_val = nil
          end
        end
        new_val
      end
      content_pieces.delete_if { |cp| !cp.present? }
      c.content = content_pieces.join("\n\n")
      c.save!
    end

  end

  task :remove_views_from_unpublished_content => :environment do
    Content.where("published = ? AND view_count > ?", false, 0).update_all(view_count: 0)
  end

  desc "Update business locations to be 2 char abbr for state"
  task :two_char_states_biz_locations => :environment do
    def save_to_tempfile(url)
      uri = URI.parse(url)
      Net::HTTP.start(uri.host, uri.port, use_ssl: (uri.scheme == 'https')) do |http|
        resp = http.get(uri.path)
        file = Tempfile.new('zipcsv', Dir.tmpdir)
        file.binmode
        file.write(resp.body)
        file.flush
        file
      end
    end

    # Get 2014 census data for postal code to state mapping
    temp_file = save_to_tempfile("https://www.irs.gov/pub/irs-soi/14zpallnoagi.csv")
    map = {}
    # {'83854' => 'ID', ...}
    CSV.foreach(temp_file.path, headers: true) do |row|
      map[row['ZIPCODE'].to_i] = row['STATE']
    end

    failed = []
    completed_count = 0
    BusinessLocation.skip_callback(:commit, :after, :reindex_associations_async, raise: false)

    BusinessLocation.find_each do |bl|
      begin
        if bl.zip?
          if state = map[ bl.zip.split('-').first.to_i ]
            bl.update_attribute 'state', state
            completed_count +=1
            next
          end
        end
      rescue Exception => e
        logger.error(e)
      end
      failed << bl
    end

    puts "Done, #{completed_count} completed"
    if failed.count > 0
      puts "Failed BusinessLocation records: (#{failed.count})"
      puts failed.map(&:id).join(', ')
    end
  end
end

