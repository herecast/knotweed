module Api
  module V3
    class DigestSerializer < ActiveModel::Serializer
      attributes :id, :digest_description, :name, :digest_send_time, :digest_send_day
    end
  end
end
