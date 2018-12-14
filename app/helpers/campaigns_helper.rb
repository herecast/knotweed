# frozen_string_literal: true

module CampaignsHelper
  def active_checkbox(active)
    attrs = { type: 'checkbox', id: 'promotion_banners_active', name: 'promotion_banners_active' }
    attrs['checked'] = 'checked' if active
    attrs
  end
end
