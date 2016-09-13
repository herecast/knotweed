module Api
  module V3
    class DigestSerializer < ActiveModel::Serializer
      attributes :listserv_id, :digest_description, :name, :digest_send_time, :digest_send_day

      def listserv_id
        object.id
      end
    end
  end
end
