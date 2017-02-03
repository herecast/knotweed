class RecordListservMetric

  def self.call(action, *args)
    self.new(*args).send(action)
  end

  def initialize(listserv_content, opts = {})
    @listserv_content        = listserv_content
    @listserv_content_metric = listserv_content.try(:listserv_content_metric)
    @opts                    = opts
  end

  private

    def create_metric
      @listserv_content.create_listserv_content_metric!(
        listserv_content_id: @listserv_content.id,
        email: @listserv_content.sender_email,
        time_sent: @listserv_content.created_at,
        post_type: @listserv_content.content_category.try(:name),
        step_reached: 'send_email'
      )
    end

    def update_metric
      return unless @listserv_content_metric.present?
      status = {}
      status.merge!(enhance_link_clicked: @opts[:enhance_link_clicked]) if @opts[:enhance_link_clicked].present?
      status.merge!(post_type: @opts[:channel_type]) if @opts[:channel_type].present?
      status.merge!(step_reached: @opts[:step_reached]) if @opts[:step_reached].present?
      @listserv_content.listserv_content_metric.update(status)
    end

    def complete_metric
      return unless @listserv_content_metric.present?
      @listserv_content.listserv_content_metric.update_attributes!(
        verified:     true,
        enhanced:     @opts[:content_id].present?,
        post_type:    @opts[:channel_type],
        username:     @listserv_content.content.try(:created_by).try(:name),
        step_reached: 'publish_post'
      )
    end

end