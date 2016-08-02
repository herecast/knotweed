module Api
  module V3
    class ContentReportsController < ApiController

      def index
        @connection = ActiveRecord::Base.connection
        sanitize_dates

        query = "SELECT (r.report_date - INTERVAL '5' HOUR) as \"Date\", u.name as \"Author\", (c.pubdate - INTERVAL '5' HOUR) as \"Publication Date\",
          c.title as \"Title\", r.view_count as \"Views\",
          r.banner_click_count as \"Ad Clicks\", (r.view_count + r.banner_click_count) * (CASE WHEN o.pay_rate_in_cents IS NOT NULL THEN (round(CAST(float8 (o.pay_rate_in_cents/100.0) as numeric), 2)) ELSE 0.05 END) as \"Payment\",
          CONCAT(c.title, ' (', (c.pubdate - INTERVAL '5' HOUR), ')') AS \"Title + PubDate\",
          (SELECT COUNT(*) FROM contents WHERE parent_id = c.id AND created_at > (r.report_date - INTERVAL '1' DAY) AND created_at < r.report_date) as \"Comments\"
          FROM content_reports r
          INNER JOIN contents c ON c.id = r.content_id
          INNER JOIN users u on u.id = c.created_by
          INNER JOIN organizations o ON o.id = c.organization_id AND r.view_count + r.banner_click_count > 0
          WHERE (r.report_date - INTERVAL '5' HOUR) >= #{@start_date} AND (r.report_date - INTERVAL '5' HOUR) < #{@end_date}
          ORDER BY u.name, c.title, report_date DESC;"
        @content_reports = @connection.execute(query)

        render json: { content_reports: @content_reports }
      end

      private

        def sanitize_dates
          @start_date = @connection.quote(params[:start_date] || Date.yesterday)
          @end_date = @connection.quote(params[:end_date] || Date.tomorrow)
        end

    end
  end
end