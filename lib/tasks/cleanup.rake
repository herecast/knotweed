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

end

