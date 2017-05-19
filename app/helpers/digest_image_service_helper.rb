module DigestImageServiceHelper
  def digest_primary_image(image_url, **image_attrs)
    ImageUrlService.optimize_image_url(url: image_url,
                                       width: image_attrs[:width],
                                       height: image_attrs[:height],
                                       do_crop: false)
  end

  def digest_profile_image(image_url, **image_attrs)
    ImageUrlService.optimize_image_url(url: image_url,
                                       width: image_attrs[:width],
                                       height: image_attrs[:height],
                                       do_crop: false)
  end

  def digest_banner_ad_image(image_url, **image_attrs)
    ImageUrlService.optimize_image_url(url: image_url,
                                       width: image_attrs[:width],
                                       height: image_attrs[:height],
                                       do_crop: false)
  end
end
