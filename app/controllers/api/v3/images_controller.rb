module Api
  module V3
    class ImagesController < ApiController
      before_filter :check_logged_in!, only: [:update, :create] 

      def create
        @content = Content.find(params[:image].delete(:content_id))
        authorize! :manage, @content
        @image = Image.new(image_params)
        if @image.save
          render json: @image, serializer: ImageSerializer, status: 201
        else
          render json: { errors: @image.errors.messages }, status: :unprocessable_entity
        end
      end

      def update
        @image = Image.find(params[:id])
        @content = Content.find(params[:image][:content_id])
        if @image.update_attributes(image_params)
          render json: @image, serializer: ImageSerializer, status: 200
        else
          render json: { errors: ["Image could not be updated"] }, status: 200
        end
      end

      def destroy
        @image = Image.find(params[:id])
        @image.destroy
        head :no_content
      end

      private
        
        def image_params
          params.require(:image).permit(
            :primary,
            :caption,
            :credit,
            :image,
            :imageable_type,
            :imageable_id,
            :source_url
          ).merge({ imageable: @content })
        end
    end
  end
end
