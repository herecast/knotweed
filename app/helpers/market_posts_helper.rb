module MarketPostsHelper

  def market_contact_display(market_post)
    display_string = ''
    display_string += market_post.contact_phone + ', ' if market_post.contact_phone.present?
    display_string += market_post.contact_email + ', ' if market_post.contact_email.present?
    display_string.chomp!(', ')
  end

  def market_post_url_for_email(market_post)
    utm_string = "?utm_medium=email&utm_source=rev-pub&utm_campaign=20151201&utm_content=#{ux2_content_path(market_post.content)}"

    url = 'http://www.dailyuv.com/uvmarket'
    if ConsumerApp.current.present?
      url = "#{ConsumerApp.current.uri}#{ux2_content_path(market_post.content)}#{utm_string}"
    elsif @base_uri.present?
      url = "#{@base_uri}/contents/#{market_post.content.id}/market_posts/#{market_post.id}#{utm_string}"
    end

    url
  end

end
