# frozen_string_literal: true

module DigestImageServiceHelper
  def digest_image_path(image_url, **image_attrs)
    ImageUrlService.optimize_image_url(url: image_url,
                                       width: image_attrs[:width],
                                       height: image_attrs[:height],
                                       do_crop: false)
  end
end
