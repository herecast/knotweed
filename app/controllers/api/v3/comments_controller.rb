module Api
  module V3
    class CommentsController < ApiController

      before_filter :check_logged_in!, only: [:create] 
      
      # @param the parent content id
      # @return all child comments
      def index
        root = Content.find params[:content_id]
        @comments = []

        if root.present?
          result_list = root.children.where(channel_type: 'Comment')
          @comments << result_list
          get_all_comments result_list
          @comments.flatten!
          @comments.sort! { |a,b| b.pubdate <=> a.pubdate }
        end
        render json: @comments, each_serializer: CommentSerializer
      end

      def create
        location_ids = [@current_api_user.try(:location_id)]

        # hard coded publication...
        pub = Publication.find_or_create_by_name 'DailyUV'

        # hard code category
        cat = ContentCategory.find_or_create_by_name 'talk_of_the_town'

        # using this hash to select the parameters we need from the params hash
        # rather than directly trying to mass assign the params hash (which might
        # contain attributes we don't want, or that aren't allowed)
        comment_hash = {}
        
        # parse out content attributes
        comment_hash[:content_attributes] = {
          title: params[:comment].delete(:title),
          parent_id: params[:comment].delete(:parent_content_id),
          location_ids: location_ids.uniq,
          authoremail: @current_api_user.try(:email),
          authors: @current_api_user.try(:name),
          raw_content: params[:comment].delete(:content),
          pubdate: Time.zone.now,
          publication_id: pub.id,
          content_category_id: cat.id
        }
        @comment = Comment.new(comment_hash)
        
        if @comment.save
          # As of Release 1.8 (first UX2 release, early June 2015), users don't have the option of
          # publishing their comments to a list, hence no list processing here in api/v2.  But, if and
          # when they do, this is where the processing would happen.  See api/v1/comments_controller.rb
          # for example.
          if @repository.present?
            @comment.content.publish(Content::DEFAULT_PUBLISH_METHOD, @repository)
          end

          render json: @comment.content, serializer: SingleCommentSerializer,
            status: 201, root: 'comment'
        else
          head :unprocessable_entity
        end
      end

      private
        
        # populates @comments with all nested child comments in the tree
        def get_all_comments(result_list)
          result_list.each do |comment|
            if comment.children.present?
              @comments << comment.children
            end
            get_all_comments comment.children
          end
        end
    end
  end
end
