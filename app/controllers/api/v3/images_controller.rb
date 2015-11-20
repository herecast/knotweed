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
        @image.primary = params[:image][:primary]
        if @image.save
          render json: {
            id: @image.id,
            image_url: @image.image.url,
            primary: @image.primary ? 1 : 0
          }, status: 200
        else
          head :unprocessable_entity
        end
      end

      def destroy
        @image = Image.find(params[:id])
        if @image.destroy
          head :no_content
        else
          head :unprocessable_entity
        end
      end
    end
  end
end
