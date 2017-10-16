class RecordContentMetric

  def self.call(*args)
    self.new(*args).call
  end

  def initialize(content, opts={})
    @content = content
    @opts    = opts
  end

  def call
    create_content_metric
    find_or_create_content_report
    increment_report_stats
  end

  private

    def create_content_metric
      ContentMetric.create!(
        content_id:  @content.id,
        event_type:  @opts[:event_type],
        user_id:     @opts[:user_id],
        user_agent:  @opts[:user_agent],
        user_ip:     @opts[:user_ip],
        client_id:   @opts[:client_id],
        location_id: @opts[:location_id]
      )
    end

    def find_or_create_content_report
      @report = @content.find_or_create_daily_report(@opts[:current_date])
    end

    def increment_report_stats
      case @opts[:event_type]
      when 'impression'
        @report.increment!(:view_count)
        @content.increment!(:view_count)
      when 'click'
        @report.increment!(:banner_click_count)
        @content.increment!(:banner_click_count)
      end
    end
end
