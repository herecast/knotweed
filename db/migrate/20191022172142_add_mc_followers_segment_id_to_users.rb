class AddMcFollowersSegmentIdToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :mc_followers_segment_id, :string
    Organization.where.not(user_id: nil).each do |organization|
      organization.user.update_attribute(
        :mc_followers_segment_id,
        organization.mc_segment_id
      )
    end
  end
end
