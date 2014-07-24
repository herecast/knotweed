class Api::CategoryCorrectionsController < Api::ApiController

  def create
    content = Content.find params[:category_correction].delete :content_id
    @category_correction = CategoryCorrection.new(params[:category_correction])
    @category_correction.content = content
    # expect old category to be passed as a param but if not,
    # assign it the content's original category
    @category_correction.old_category = content.category unless @category_correction.old_category.present?
    if @category_correction.save
      render text: "#{@category_correction.content.id} updated"
    else
      render text: "There was an error creating the category correction.", status: 500
    end
  end

end
