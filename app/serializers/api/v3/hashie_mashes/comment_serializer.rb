module Api
  module V3
    module HashieMashes
      class CommentSerializer < HashieMashSerializer
        attributes :id, :content_id, :title, :content, :parent_content_id,
          :published_at, :user_id, :user_name,:user_image_url

        def user_id
          object.created_by.try :id
        end

        def user_name
          object.created_by.try :name
        end

        def user_image_url
          object.created_by.try :avatar_url
        end
      end
    end
  end
end
