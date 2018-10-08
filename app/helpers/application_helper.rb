module ApplicationHelper
  CONFIG_CONTROLLERS = ["locations", "features", "sidekiq_wrapper"]

  def display_base_errors resource
    return '' if (resource.errors.empty?) or (resource.errors[:base].empty?)
    messages = resource.errors[:base].map { |msg| content_tag(:p, msg) }.join
    html = <<-HTML
    <div class="alert alert-error alert-block">
      <button type="button" class="close" data-dismiss="alert">&#215;</button>
      #{messages}
    </div>
    HTML
    html.html_safe
  end

  # taken from http://railscasts.com/episodes/196-nested-model-form-revised		
  def link_to_add_fields(name, f, association)		
    new_object = f.object.send(association).klass.new		
    id = new_object.object_id		
    fields = f.fields_for(association, new_object, child_index: id) do |builder|		
      render(association.to_s.singularize + "_fields", f: builder)		
    end		
    content_tag(:span, name, class: "btn btn-success association_add_fields", data: {id: id, fields: fields.gsub("\n", "")})		
  end

  def is_config_controller_class
    if CONFIG_CONTROLLERS.include? controller_name
      return "in"
    else
      return ""
    end
  end

  def is_payments_controller_class
    if ["payments", "payment_recipients"].include? controller_name
      return "in"
    else
      return ""
    end
  end

end
