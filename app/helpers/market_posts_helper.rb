module MarketPostsHelper

  def market_contact_display(market_post)
    display_string = ''
    display_string += market_post.contact_phone + ', ' if market_post.contact_phone.present?
    display_string += market_post.contact_email + ', ' if market_post.contact_email.present?
    display_string.chomp!(', ')
  end

  def market_post_url_for_email(market_post)

    url = 'http://www.dailyuv.com/market'
    if ConsumerApp.current.present?
      url = "#{ConsumerApp.current.uri}/market/#{market_post.content.id}"
    elsif @base_uri.present?
      url = "#{@base_uri}/market/#{market_post.content.id}"
    end

    url
  end

end
