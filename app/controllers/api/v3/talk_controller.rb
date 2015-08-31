module Api
  module V3
    class TalkController < ApiController
      
      before_filter :check_logged_in!, only: [:index, :show]

      def index
        opts = {}
        opts = { select: '*, weight()' }
        opts[:order] = 'pubdate DESC'
        opts[:with] = {}
        opts[:conditions] = {}
        opts[:page] = params[:page] || 1
        opts[:per_page] = params[:per_page] || 14
        opts[:conditions][:published] = 1 if @repository.present?
        opts[:sql] = { include: [:images, :publication, :root_content_category] }
        if @requesting_app.present?
          allowed_pubs = @requesting_app.publications
          opts[:with].merge!({pub_id: allowed_pubs.collect{|c| c.id} })
        end

        location_condition = @current_api_user.location_id

        root_talk_cat = ContentCategory.find_by_name 'talk_of_the_town'

        opts[:with].merge!({
          all_loc_ids: [location_condition], 
          root_content_category_id: root_talk_cat.id
        })

        if params[:query].present?
          query = Riddle::Query.escape(params[:query]) 
        else
          query = ''
        end

        @talk = Content.search query, opts
        render json: @talk, each_serializer: TalkSerializer
      end

      def show
        @talk = Content.find params[:id]
        if @talk.try(:root_content_category).try(:name) != 'talk_of_the_town'
          head :no_content
        else
          render json: @talk, serializer: DetailedTalkSerializer, root: 'talk'
        end
      end

    end
  end
end
