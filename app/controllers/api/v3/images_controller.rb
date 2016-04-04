module Api
  module V3
    class ImagesController < ApiController
      def create
        content = Content.find(params[:image].delete(:content_id))

        @image = Image.new(params[:image].merge({ imageable: content }))
        if @image.save
          render json: @image, serializer: ImageSerializer, status: 201
        else
          render json: { errors: @image.errors.messages }, status: :unprocessable_entity
        end
      end

      # currently the update call only allows turning the primary flag on or off
      def update
        @image = Image.find(params[:id])
        # this action can't actually fail so we don't need a conditional here
        @image.update_attribute :primary, params[:image][:primary]
        render json: @image, serializer: ImageSerializer, status: 200
      end

      def destroy
        @image = Image.find(params[:id])
        @image.destroy
        head :no_content
      end
    end
  end
end
