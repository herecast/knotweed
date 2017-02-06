class AddListservContentReferenceToPromotionListserv < ActiveRecord::Migration
  def change
    add_column :promotion_listservs, :listserv_content_id, :integer
  end
end
