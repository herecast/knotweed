class RecordContentMetric

  def self.call(*args)
    self.new(*args).call
  end

  def initialize(content, event_type, current_date, opts={})
    @content      = content
    @event_type   = event_type
    @current_date = current_date
    @opts         = opts
  end

  def call
    create_content_metric
    find_or_create_content_report
    increment_report_stats
  end

  private

    def create_content_metric
      ContentMetric.create!(
        event_type: @event_type,
        content_id: @content.id,
        user_id:    @opts[:user_id],
        user_agent: @opts[:user_agent],
        user_ip:    @opts[:user_ip],
        client_id:  @opts[:client_id]
      )
    end

    def find_or_create_content_report
      @report = @content.find_or_create_daily_report(@current_date)
    end

    def increment_report_stats
      case @event_type
      when 'impression'
        @report.increment!(:view_count)
        @content.increment!(:view_count)
      when 'click'
        @report.increment!(:banner_click_count)
        @content.increment!(:banner_click_count)
      end
    end
end
