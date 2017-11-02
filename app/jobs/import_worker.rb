class ImportWorker < ApplicationJob
  queue_as :imports_and_publishing

  after_enqueue do
    import_job = self.arguments[0]
    # continuous jobs are essentially always "running" even though we're
    # just polling every 5 seconds (this is the behavior we had under
    # delayed job, too)
    status = import_job.job_type == 'continuous' ? 'running' : 'scheduled'
    attrs = { sidekiq_jid: self.job_id, status: status }
    attrs[:next_scheduled_run] = Time.at(self.scheduled_at).
      to_datetime.change(usec: 0) if self.scheduled_at.present?

    import_job.update attrs
  end

  def perform(import_job)
    begin
      @import_job = import_job
      @record = @import_job.import_records.create

      @import_job.update_attribute :status, 'running'

      if Time.current > ImportJob.backup_start and Time.current < ImportJob.backup_end
        log(:info, "rescheduling #{@import_job.job_type} job: #{@import_job.name} during backup")
        ImportWorker.set(wait_until: ImportJob.backup_end).perform_later(@import_job) and return
      else
        log(:info, "source path: #{@import_job.full_import_path}")
        if @import_job.source_uri.present? # web scraping import
          data = run_parser(@import_job.source_uri)
        elsif Figaro.env.imports_bucket.present?
          data = parse_s3_files
        else
          data = []
          log(:info, "App is not configured with an import bucket; nothing could be imported.")
        end
        process_data(data)
      end

      if @import_job.job_type == ImportJob::CONTINUOUS
        if @import_job.stop_loop
          # this means a user has tried to break out of continuous job running
          # so we need to A) not queue another job and B) reset stop_loop to false
          # so that when they restart it, it works fine.
          @import_job.update stop_loop: false, status: 'success', sidekiq_jid: nil,
            next_scheduled_run: nil
        else
          # keep continuous jobs running
          # to match old behavior, and save us a little Sidekiq working,
          # schedule for *slightly* in the future
          @import_job.update sidekiq_jid: ImportWorker.set(wait_until: 5.seconds.from_now).
            perform_later(@import_job)
        end
      elsif @import_job.job_type == ImportJob::RECURRING
        scheduled_jid = ImportWorker.set(wait_until: @import_job.next_run_time).
          perform_later(@import_job).job_id
        @import_job.update status: 'scheduled', sidekiq_jid: scheduled_jid
      else
        @import_job.update status: 'success', sidekiq_jid: nil
      end
    rescue Exception => e
      handle_error(e)
    end
  end

  private

  def log(log_level, message)
    logger.send(log_level, "[ImportRecord #{@record.try(:id)}] #{message}")
  end

  def parse_s3_files
    connection = Fog::Storage.new({
      :provider                 => 'AWS',
      :aws_access_key_id        => Figaro.env.aws_access_key_id,
      :aws_secret_access_key    => Figaro.env.aws_secret_access_key
    })

    files = connection.directories.get(Figaro.env.imports_bucket,
                                       prefix: @import_job.inbound_prefix).files
    data = []
    files.each do |file|
      log(:debug, "running parser on: #{Figaro.env.imports_bucket}/#{file.key}")
      begin
        key = file.key
        path = "s3://#{Figaro.env.imports_bucket}/#{key}"
        # run the parser and then move the file to the outbound_prefix
        data += run_parser(path)
        # copy to new path
        connection.copy_object(
          Figaro.env.imports_bucket,
          key,
          Figaro.env.imports_bucket,
          key.gsub(@import_job.inbound_prefix, @import_job.outbound_prefix)
        )
        # delete original
        connection.delete_object(Figaro.env.imports_bucket, key)
      rescue StandardError => bang
        log(:error, "failed to parse #{path}: #{bang}")
        log(:error, "backtrace for #{path}: #{bang.backtrace.join("\n")}")
      end
    end
    data
  end

  def process_data(records)
    docs_to_contents(records)
  end

  # runs the parser's parse_file method on a file located at path
  # outputs an array of articles (if parser is correct)
  #
  def run_parser(path)
    load "#{ImportJob::PARSER_PATH}/#{@import_job.parser.filename}"
    resp = parse_file(path, @import_job.config)
    # if JSON
    if resp.is_a? String
      JSON.parse resp
    else
      resp
    end
  end

  # accepts array of articles
  # and creates content entries for them
  def docs_to_contents(docs)
    successes = failures = filtered = 0
    created_contents = []
    docs.each do |article|
      next if article.empty?
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
        # filter out emails that we sent
        was_filtered = false
        was_filtered, reason = import_filter(article)
        if was_filtered
          log(:info, "#{reason}")
          filtered += 1
        else
          c = Content.create_from_import_job(article, @import_job)
          created_contents.push(c)
          log(:info, "content #{c.id} created")
          successes += 1
          if @import_job.automatically_publish and @import_job.repository.present?
            c.publish(@import_job.publish_method, @import_job.repository)
          end
        end
      rescue StandardError => bang
        log(:error, "failed to process content #{article['title']}: #{bang}")
        log(:error, "stacktrace for #{article['title']}: #{bang.backtrace.join("\n")}")
        failures += 1
      end
    end
    log(:info, "successes: #{successes}")
    log(:info, "failures: #{failures}")
    log(:info, "filtered: #{filtered}")
    @record.items_imported += successes
    @record.failures += failures
    @record.filtered += filtered
    @record.save
    created_contents
  end

  def import_filter(article)
    filtered = false
    reason = ''
    original_content_id = original_event_instance_id = 0
    original_content_id = article['X-Original-Content-Id'] if article.has_key? 'X-Original-Content-Id'
    if original_content_id > 0
      c = Content.find(original_content_id)
      filtered = c.present?
      reason = "content with X-Original-Content-Id #{article['X-Original-Content-Id']} filtered"
    end
    # if this has our proprietary 'X-Original-Event-Instance-Id' key in the header, it means this was created on
    # our site so don't create new content. If so, AND it's an event, it implies it's already been curated (i.e. 'has_event-calendar')
    original_event_instance_id = article['X-Original-Event-Instance-Id'] if article.has_key? 'X-Original-Event-Instance-Id'
    if original_event_instance_id > 0
      c = EventInstance.find(original_event_instance_id).event.content
      filtered = c.present?
      reason = "event instance with X-Original-Event-Instance-Id #{article['X-Original-Event-Instance-Id']} filtered"
    end
    return filtered, reason
  end

  def handle_error(exception)
    @import_job.update status: 'failed', next_scheduled_run: nil,
      sidekiq_jid: nil
    log(:info, "input: #{@import_job.full_import_path}")
    log(:info, "parser: #{ImportJob::PARSER_PATH}/#{@import_job.parser.filename}") if @import_job.parser.present?
    log(:error, "error: #{exception}")
    if @import_job.notifyees.present?
      JobMailer.error_email(@record, exception.to_s).deliver_later
    end
    log(:error, "backtrace: #{exception.backtrace.join("\n")}")
    log(:info, "#{@import_job.inspect}")

    # in order to maintain continuity with the interface and existing import job behavior,
    # we aren't allowing any exceptions to bubble up into Sidekiq. This is really not
    # the best use of Sidekiq, but coming up with another strategy would be substantially
    # more work and would probalby have to involve rewriting the parsers so that each
    # job run is more atomic and we don't have to worry about it retrying. SO since we're
    # about to rewrite the email import stuff out of this code anyway, I am explicitly NOT
    # raising the exception
  end
end
