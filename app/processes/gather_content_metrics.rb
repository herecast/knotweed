class GatherContentMetrics
  def self.call(*args)
    self.new(*args).call
  end

  def initialize(opts = {})
    @opts            = opts
    @owner    = opts[:owner]
    @start_date      = opts[:start_date]
    @end_date        = opts[:end_date]
  end

  def call
    return {
      promo_click_thru_count: promo_click_thru_count,
      view_count: view_count,
      comment_count: comment_count,
      daily_view_counts: daily_view_counts,
      daily_promo_click_thru_counts: daily_promo_click_thru_counts
    }
  end

  private

  def promo_click_thru_count
    contents.sum(:banner_click_count).to_i
  end

  def view_count
    contents.sum(:view_count).to_i
  end

  def comment_count
    contents.sum(:comment_count).to_i
  end

  def contents
    if @owner.present?
      @contents ||= @owner.contents.where(pubdate: @start_date..@end_date)
    else
      @contents = []
    end
  end

  def content_reports
    base_scope = ContentReport.where(report_date: @start_date..(@end_date + 1.day))
    if @owner.is_a? Organization
      @content_reports ||= base_scope
                           .where("content_id IN (select id from contents where organization_id=#{@owner.id})")
    elsif @owner.is_a? User
      @content_reports ||= base_scope
                           .joins(:content).where('contents.created_by_id = ?', @owner.id)
    else
      []
    end
  end

  def daily_view_counts
    (@start_date..@end_date).map do |date|
      reports = content_reports.select { |cr| cr.report_date.to_date == date }
      {
        report_date: date.to_s,
        view_count: reports.present? ? reports.sum(&:view_count).to_i : 0
      }
    end
  end

  def daily_promo_click_thru_counts
    (@start_date..@end_date).map do |date|
      reports = content_reports.select { |cr| cr.report_date.to_date == date }
      {
        report_date: date.to_s,
        banner_click_count: reports.present? ? reports.sum(&:banner_click_count).to_i : 0
      }
    end
  end
end
