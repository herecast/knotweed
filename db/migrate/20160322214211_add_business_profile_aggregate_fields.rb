class AddBusinessProfileAggregateFields < ActiveRecord::Migration
  def up
    add_column :business_profiles, :feedback_count, :integer, default: 0
    add_column :business_profiles, :feedback_recommend_avg, :float, default: 0
    add_column :business_profiles, :feedback_price_avg, :float, default: 0
    add_column :business_profiles, :feedback_satisfaction_avg, :float, default: 0
    add_column :business_profiles, :feedback_cleanliness_avg, :float, default: 0


    execute "
      UPDATE business_profiles bp
      INNER JOIN (
        SELECT bf.business_profile_id, count(bf.id) as count,
          avg(bf.satisfaction) as satisfaction, avg(bf.price) as price, avg(bf.cleanliness) as cleanliness, avg(bf.recommend) as recommend
        FROM business_feedbacks bf
        GROUP BY bf.business_profile_id
      ) as agg
      ON agg.business_profile_id = bp.id
      SET bp.feedback_count = agg.count,
          bp.feedback_satisfaction_avg = agg.satisfaction,
          bp.feedback_cleanliness_avg = agg.cleanliness,
          bp.feedback_recommend_avg = agg.recommend,
          bp.feedback_price_avg = agg.price
    "
  end

  def down
    remove_column :business_profiles, :feedback_count
    remove_column :business_profiles, :feedback_recommend_avg
    remove_column :business_profiles, :feedback_satisfaction_avg
    remove_column :business_profiles, :feedback_cleanliness_avg
    remove_column :business_profiles, :feedback_price_avg
  end
end
