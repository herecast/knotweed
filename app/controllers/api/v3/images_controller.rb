module Api
  module V3
    class ImagesController < ApiController
      before_filter :check_logged_in!, only: [:update, :create] 

      def create
        content = Content.find(params[:image].delete(:content_id))
        authorize! :manage, content
        @image = Image.new(params[:image].merge({ imageable: content }))
        if @image.save
          render json: @image, serializer: ImageSerializer, status: 201
        else
          render json: { errors: @image.errors.messages }, status: :unprocessable_entity
        end
      end

      def update
        @image = Image.find(params[:id])
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
          params.require(:image).permit(:primary, :caption)
        end
    end
  end
end
