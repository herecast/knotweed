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
      @import_job.import_records.create
      @log = @import_job.last_import_record.log_file

      @import_job.update_attribute :status, 'running'

      if Time.current > ImportJob.backup_start and Time.current < ImportJob.backup_end
        @log.info("#{Time.current}: rescheduling #{@import_job.job_type} job: #{@import_job.name} during backup")
        ImportWorker.set(wait_until: ImportJob.backup_end).perform_later(@import_job) and return
      else
        @log.info("#{Time.current}: source path: #{@import_job.source_path}")
        @log.info("#{Time.current}: Running parser at #{Time.current}")
        if @import_job.source_path =~ /^#{URI::regexp}$/
          data = run_parser(@import_job.source_path)
        else
          data = parse_file_tree(@import_job.source_path)
        end
        process_data(data)
      end

      if @import_job.job_type == ImportJob::CONTINUOUS
        if @import_job.stop_loop
          # this means a user has tried to break out of continuous job running
          # so we need to A) not queue another job and B) reset stop_loop to false
          # so that when they restart it, it works fine.
          @import_job.update stop_loop: false, status: 'success', sidekiq_jid: nil
        else
          # keep continuous jobs running
          # to match old behavior, and save us a little Sidekiq working,
          # schedule for *slightly* in the future
          @import_job.update sidekiq_jid: ImportWorker.set(wait_until: 5.seconds.from_now).
            perform_later(@import_job)
        end
      elsif @import_job.job_type == ImportJob::RECURRING
        @import_job.update status: 'scheduled', 
          sidekiq_jid: ImportWorker.set(wait_until: @import_job.next_run_time).
          perform_later(@import_job)
      else
        @import_job.update status: 'success', sidekiq_jid: nil
      end
    rescue Exception => e
      handle_error(e)
    end
  end

  private

  def parse_file_tree(source_path)
    data = []
    Find.find(source_path) do |path|
      if FileTest.directory?(path)
        next
      else
        @log.debug("#{Time.current}: running parser on path: #{path}")
        begin
          data += run_parser(path)
        rescue StandardError => bang
          @log.error("#{Time.current}: failed to parse #{path}: #{bang}")
        end
      end
    end
    data
  end

  def process_data(records)
    update_prerender(docs_to_contents(records))
  end

  def update_prerender(records)
    # no need to prerender talk items since they are not sharable
    records.reject { |r| r.root_content_category.try(:name) == 'talk_of_the_town' }
    @import_job.consumer_apps.each do |consumer_app|
      records.each do |content|
        HTTParty.post("http://api.prerender.io/recache", body: {prerenderToken: Figaro.env.prerender_token,
                      url: consumer_app.uri + content.ux2_uri }.to_json,
                      :headers => {'Content-Type' => 'application/json'})
      end
    end
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
    import_record = @import_job.last_import_record
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
          @log.info("#{Time.current}: #{reason}")
          filtered += 1
        else
          c = Content.create_from_import_job(article, @import_job)
          created_contents.push(c)
          @log.info("#{Time.current}: content #{c.id} created")
          successes += 1
          if @import_job.automatically_publish and @import_job.repository.present?
            c.publish(publish_method, repository)
          end
        end
      rescue StandardError => bang
        @log.error("#{Time.current}: failed to process content #{article['title']}: #{bang}")
        failures += 1
      end
    end
    @log.info("#{Time.current}: successes: #{successes}")
    @log.info("#{Time.current}: failures: #{failures}")
    @log.info("#{Time.current}: filtered: #{filtered}")
    import_record.items_imported += successes
    import_record.failures += failures
    import_record.filtered += filtered
    import_record.save
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
    @import_job.update_attribute :status, 'failed'
    @log.info "#{Time.current}: input: #{@import_job.source_path}"
    @log.info "#{Time.current}: parser: #{ImportJob::PARSER_PATH}/#{@import_job.parser.filename}" if @import_job.parser.present?
    @log.error "#{Time.current}: error: #{exception}"
    if @import_job.notifyees.present?
      JobMailer.error_email(@import_job.last_import_record, exception).deliver_now
    end
    @log.error "#{Time.current}: backtrace: #{exception.backtrace.join("\n")}"
    @log.info "#{@import_job.inspect}"
    raise(exception)
  end
end
