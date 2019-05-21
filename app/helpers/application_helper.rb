# frozen_string_literal: true

module ApplicationHelper
  CONFIG_CONTROLLERS = %w[features sidekiq_wrapper].freeze

  def display_base_errors(resource)
    return '' if resource.errors.empty? || resource.errors[:base].empty?

    messages = resource.errors[:base].map { |msg| content_tag(:p, msg) }.join
    html = <<-HTML
    <div class="alert alert-error alert-block">
      <button type="button" class="close" data-dismiss="alert">&#215;</button>
      #{messages}
    </div>
    HTML
    html.html_safe
  end

  def is_config_controller_class
    if CONFIG_CONTROLLERS.include? controller_name
      'in'
    else
      ''
    end
  end

  def is_payments_controller_class
    if %w[payments payment_recipients].include? controller_name
      'in'
    else
      ''
    end
  end
end
