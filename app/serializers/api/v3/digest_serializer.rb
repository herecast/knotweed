module Api
  module V3
    class DigestSerializer < ActiveModel::Serializer
      attributes :id, :digest_description, :name, :digest_send_time, :digest_send_day, :next_digest_send_time

      def digest_send_time
        if object.digest_send_time
          object.digest_send_time.strftime('%l:%M %p').strip
        end
      end
    end
  end
end
