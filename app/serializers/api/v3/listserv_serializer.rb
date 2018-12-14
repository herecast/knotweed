module Api
  module V3
    class ListservSerializer < ActiveModel::Serializer
      attributes :id, :name, :next_digest_send_time, :digest_send_time
    end
  end
end
