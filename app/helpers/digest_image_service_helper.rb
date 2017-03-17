module DigestImageServiceHelper
  def digest_primary_image(image_url)
    ImageUrlService.optimize_image_url(url: image_url,
                                       width: nil,
                                       height: nil,
                                       do_crop: false)
  end

  def digest_profile_image(image_url)
    ImageUrlService.optimize_image_url(url: image_url,
                                       width: nil,
                                       height: nil,
                                       do_crop: false)
  end

  def digest_banner_ad_image(image_url)
    ImageUrlService.optimize_image_url(url: image_url,
                                       width: nil,
                                       height: nil,
                                       do_crop: false)
  end
end
