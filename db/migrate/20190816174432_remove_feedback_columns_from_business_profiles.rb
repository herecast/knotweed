class RemoveFeedbackColumnsFromBusinessProfiles < ActiveRecord::Migration[5.1]
  def change
    remove_column :business_profiles, :feedback_count, :integer
    remove_column :business_profiles, :feedback_recommend_avg, :float
    remove_column :business_profiles, :feedback_price_avg, :float
    remove_column :business_profiles, :feedback_satisfaction_avg, :float
    remove_column :business_profiles, :feedback_cleanliness_avg, :float
  end
end
