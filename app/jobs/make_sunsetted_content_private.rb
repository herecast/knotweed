class MakeSunsettedContentPrivate < ApplicationJob
  def perform
    sunsetted_content = Content.where.not(sunset_date: nil)
                               .where('sunset_date < ?', Time.current)
    sunsetted_content.each { |c| c.update_attribute(:biz_feed_public, false) }
  end
end