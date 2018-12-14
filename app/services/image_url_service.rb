module ImageUrlService
  extend self

  def optimize_image_urls(html_text:, default_width: nil, default_height: nil, default_crop: true)
    doc = Nokogiri::HTML::DocumentFragment.parse(html_text)
    doc.css('img').each do |img|
      if img.has_attribute?('src')
        unoptimized_url = img['src']
        width, height = choose_dimensions(img, default_width, default_height)
        img['src'] = optimize_image_url(url: unoptimized_url, width: width, height: height, do_crop: default_crop)
      end
    end

    doc.to_html
  end

  # This method should be functionally identical to the makeOptimizedImageUrl in
  # https://github.com/subtextmedia/subtext-ui/blob/master/app/utils/optimize-image-url.js.
  def optimize_image_url(url:, width:, height:, do_crop:)
    result = url

    optimized_image_uri = ENV['OPTIMIZED_IMAGE_URI']
    if optimized_image_uri.present? && url && url =~ /^http/i && hostname_is_allowed(url) && width && height
      url_no_protocol = url.sub(/^https?:\/\//, '')
      optimized_image_quality = ENV['OPTIMIZED_IMAGE_QUALITY'] || "80"
      quality = "filters:quality(#{optimized_image_quality})"

      if do_crop
        result = [optimized_image_uri, 'unsafe', "#{width}x#{height}", 'smart', quality, url_no_protocol].join('/')
      else
        result = [optimized_image_uri, 'unsafe', 'fit-in', "#{width}x#{height}", quality, url_no_protocol].join('/')
      end
    end

    result
  end

  private

  def hostname_is_allowed(url)
    # Memoize the computed list of hostnames.
    @whitelisted_hostnames ||= compute_whitelisted_hostnames

    @whitelisted_hostnames.include?(URI.parse(url).hostname)
  end

  def compute_whitelisted_hostnames
    # The incoming +ENV['IMOPT_ALLOWED_SOURCES']+ list can contain hostnames, e.g. 'd3ctw1a5413a3o.cloudfront.net'
    # or URIs, e.g. 'https://d3ctw1a5413a3o.cloudfront.net'.  We want to convert each item to a simple hostname.
    whitelisted_sources = ENV['IMOPT_ALLOWED_SOURCES'] || '["d3ctw1a5413a3o.cloudfront.net", "knotweed.s3.amazonaws.com", "subtext-misc.s3.amazonaws.com"]'
    JSON.parse(whitelisted_sources).map { |src|
      src =~ /^http/i ? src.sub(/^https?:\/\//, '') : src
    }.uniq
  end

  # Returns the optimized width and height for the given +img+ element.
  # If one or both of the two values cannot be determined, a nil will be returned
  # for the indeterminate value(s), causing the subsequent call to +optimize_image_url+
  # to be a NO-OP.
  def choose_dimensions(img_elem, default_width, default_height)
    width, height = default_width, default_height # Until we determine otherwise

    # CSS styling takes precedence over explicit +width+ and +height+ attributes, so
    # look for the explicit attributes first and then override them below if the CSS
    # styling yields values.
    width  = img_elem['width'] if img_elem.has_attribute?('width')
    height = img_elem['height'] if img_elem.has_attribute?('height')

    # Attempt to override the explicit attribute values with CSS style values.
    if img_elem.has_attribute?('style')
      css_width  = extract_css_dimension(img_elem['style'], :width)
      css_height = extract_css_dimension(img_elem['style'], :height)

      width  = css_width  if css_width
      height = css_height if css_height
    end

    return width, height
  end

  # Returns nil if the target CSS dimension cannot be determined.
  def extract_css_dimension(style_str, target_dimension)
    # We are only interested in the style components that have the target dimension in their names
    # and have numeric pixel values.
    dimension_styles = style_str
                       .split(';')
                       .map { |s| s.gsub(/\s+/, '') }
                       .grep(/#{target_dimension}/i)
                       .grep(/\d+px$/i)

    # Sort by style string length to prefer a style like +width:30px+ to one with a +min-+ or +max-+ prefix.
    # And if you have to choose between a +min-+ or a +max-+, choose the max by preferring the one that's first
    # in alphabetical order.
    best_style = dimension_styles.min_by { |s|
      style_name = s.split(":").first
      [style_name.size, style_name]
    }

    numeric_match = best_style.to_s.split(':').last.to_s.match(/\d+/)
    numeric_match && numeric_match[0]
  end
end
