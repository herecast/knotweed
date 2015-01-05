class Api::MailController < Api::ApiController

  require 'mail'

  def create
    raw_email = params['email']

    if raw_email.present?
      eml = Mail.new(raw_email)

      hash_email = parse_message(eml)

      content = persist_email(hash_email)
      if content.present?
        render text: "Email with guid #{content.guid} saved and published as id #{content.id}",  status: 200
      else
        render text: "Email not saved", status: 500
      end
    end

  end


  def parse_message(eml)
    #
    # extracted from listserv_capture_no_gmail.rb parse_file()

    email = {}
    # should this be config?
    #email["source"] = config["source"] # NOW DYNAMIC FROM LOCATION
    email['doctype'] = 'http://proton.semanticweb.org/2004/12/protonu#EMail'
    email['language'] = "en"
    email['origin'] = 'GMail'
    #email['copyright'] = config["copyright"]

    # get author email
    email["authoremail"] = eml.from.join(",")

    # get authors
    if /\A((\w| )+)</.match(eml["from"].to_s) # pull author out of ["from"] hash entry
      email["authors"] = /\A((\w| )+)</.match(eml["from"].to_s)[1].strip
    elsif email["authoremail"].present?
      email["authors"] = email["authoremail"]
    else
      email["authors"] = eml.sender.to_s
    end

    # expecting regexp to match title and location from the email subject
    # regexp should return title as [1] and location as [2]
    subj = /\[(\w+)( \w+)*\](.+)/.match(eml.subject)
    if subj
      email['location'] = subj[1].strip
    end
    email['title'] = eml.subject

    email['in_reply_to'] = eml.in_reply_to

    email['guid'] = eml.message_id
    email['timestamp'] = email['pubdate'] = eml.date

    email['source'] = "#{email['location']} Listserve"

    # GOAL: exclude "boilerplate" from the top and bottom of the email.
    #
    # Strategy 1: if the email is multipart, the Mail method html_part gets the first part
    # with MIME type text/html. That seems to be doing exactly what we want,
    # in particular, excluding the boilerplate.
    if eml.multipart? and eml.html_part.present?
      body = eml.html_part.body.to_s.encode("UTF-8", undef: :replace, invalid: :replace, replace: "")
      email["content"] = body
      # if the email is not multipart, or for some reason, html_part doesn't get us anything
    else
      if eml.text_part.present?
        body = eml.text_part.body.to_s.encode("UTF-8", undef: :replace, invalid: :replace, replace: "")
      else
        body = eml.body.to_s.encode("UTF-8", undef: :replace, invalid: :replace, replace: "")
      end

      # get boundary phrases from attached files
      # TODO: need to figure out some way not to load this stuff with EVERY email

      b1_file = File.open("./lib/parsers/boundary_one_possibles.txt")
      boundary_one_possibles = b1_file.readlines.map{ |l| [Regexp.new(l.strip), l.strip.length] }
      b2_file = File.open("./lib/parsers/boundary_two_possibles.txt")
      boundary_two_possibles = b2_file.readlines.map{ |l| [Regexp.new(l.strip), l.strip.length] }

      content_begin = 0
      content_end = body.length

      # establish content begin
      boundary_one_possibles.each do |b1|
        b1_match = body.index(b1[0])
        if b1_match and (b1_match + b1[1]) > content_begin
          content_begin = b1_match + b1[1]
        end
      end
      # establish content end
      boundary_two_possibles.each do |b2|
        b2_match = body.index(b2[0])
        if b2_match and b2_match < content_end
          content_end = b2_match
        end
      end

      email["content"] = body[content_begin..content_end]
    end

    email

  end

  def persist_email(article)
    #
    # extracted from import_job.rb doc_to_contents()
    #
    success = false

    # trim all fields so we don't get any unnecessary whitespace
    article.each_value { |v| v.strip! if v.is_a? String and v.frozen? == false }
    # remove leading empty <p> tags from content
    if article.has_key? "content"
      p_tags_match = article["content"].match(/\A(<p>|<\/p>| )+/)
      if p_tags_match
        content_start = p_tags_match[0].length - 1
        article["content"].slice!(0..content_start)
      end
    end

    begin
      job = ImportJob.find(2454)
      if job
        log = job.last_import_record.log_file
      else
        log = Logger.new("#{Rails.root}/log/contents.log")
      end
      c = Content.create_from_import_job(article, job)
#      log.info("content #{c.id} created")
      if job.present? and job.automatically_publish and job.repository.present?
        c.publish(job.publish_method, job.repository)
      end
      success = true
    rescue StandardError => bang
#      log.error("failed to process content: #{bang}")
      c = nil
    end

    c

  end
end