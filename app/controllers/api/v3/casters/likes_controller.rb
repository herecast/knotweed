# frozen_string_literal: true

module Api
  module V3
    class Casters::LikesController < ApiController
      before_action :check_logged_in!

      def index
        authorize! :manage, Like
        caster = Caster.find(params[:caster_id])
        render json: caster.likes
      end

      def create
        authorize! :create, Like
        caster = Caster.find(params[:caster_id])
        @like = caster.likes.build(like_params)
        if @like.save
          minimal_content_reindex
          render json: { like: @like }, status: :created
        else
          render json: {}, status: :bad_request
        end
      end

      def update
        @like = Like.find(params[:id])
        authorize! :update, @like
        if @like.update(like_params)
          minimal_content_reindex
          render json: { like: @like }, status: :ok
        else
          render json: {}, status: :bad_request
        end
      end

      def destroy
        like = Like.find(params[:id])
        authorize! :destroy, like
        if like.destroy
          render json: {}, status: :ok
        else
          render json: {}, status: :bad_request
        end
      end

      private

      def like_params
        params.require(:like).permit(
          :content_id,
          :event_instance_id
        )
      end

      def minimal_content_reindex
        @like.content.reindex(:like_count_data)
      end
    end
  end
end
