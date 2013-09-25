class Admin::ParsersController < Admin::AdminController
  
  # method for returning parameter fields via ajax
  def parameters
    @parameters = Parameter.where("parser_id = ?", params[:id])
    render partial: "admin/parsers/partials/parameters_fields"
  end
  
end
