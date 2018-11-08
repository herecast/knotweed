module MarketPostsHelper
  include ContentsHelper

  def market_contact_display(market_post)
    display_string = ''
    display_string += market_post.contact_phone + ', ' if market_post.contact_phone.present?
    display_string += market_post.contact_email + ', ' if market_post.contact_email.present?
    display_string.chomp!(', ')
  end

  def market_post_url_for_email(market_post)
    utm_string = "?utm_medium=email&utm_source=rev-pub&utm_content=#{ux2_content_path(market_post.content)}"
    url = url_for_consumer_app("/#{market_post.content.id}#{utm_string}")

    url
  end

end
