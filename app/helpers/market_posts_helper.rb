module MarketPostsHelper

  def market_contact_display(market_post)
    display_string = ''
    display_string += market_post.contact_phone + ', ' if market_post.contact_phone.present?
    display_string += market_post.contact_email + ', ' if market_post.contact_email.present?
    display_string.chomp!(', ')
  end

  def market_post_url_for_email(market_post)
    url = 'http://www.dailyuv.com/uvmarket'
    if Thread.current[:consumer_app].present?
      url = "#{Thread.current[:consumer_app].uri}#{ux2_content_path(market_post.content)}"
    elsif @base_uri.present?
      url = "#{@base_uri}/contents/#{market_post.content.id}/market_posts/#{market_post.id}"
    end

    url
  end

end
