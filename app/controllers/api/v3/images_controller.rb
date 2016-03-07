module Api
  module V3
    class ImagesController < ApiController
      def create
        content = Content.find(params[:image][:content_id])

        @image = Image.create(image: params[:image][:image], 
                     primary: params[:image][:primary], imageable: content)
        render json: {
          id: @image.id,
          image_url: @image.image.url,
          primary: @image.primary ? 1 : 0
        }, status: 201
      end

      def update
        @image = Image.find(params[:id])
        # this action can't actually fail so we don't need a conditional here
        @image.update_attribute :primary, params[:image][:primary]
        render json: {
          id: @image.id,
          image_url: @image.image.url,
          primary: @image.primary ? 1 : 0
        }, status: 200
      end

      def destroy
        @image = Image.find(params[:id])
        @image.destroy
        head :no_content
      end
    end
  end
end
