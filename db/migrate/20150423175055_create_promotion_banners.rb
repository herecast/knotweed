class CreatePromotionBanners < ActiveRecord::Migration
  def change
    create_table :promotion_banners do |t|
      t.string :banner_image
      t.string :redirect_url

      t.timestamps
    end

    # polymorphic relationship to 'subclasses'
    add_column :promotions, :promotable_id, :integer
    add_column :promotions, :promotable_type, :string

    # migrate existing promotions to promotion / promotion_banner pairs
    say 'migrating existing promotions to promotion-banner pairs'
    Promotion.all.each do |p|
      p.promotable = PromotionBanner.create(banner_image: p.banner, redirect_url: p.target_url)
      p.save
    end
    
    say 'moving associated images on AWS'
    connection = Fog::Storage.new({
      provider: "AWS",
      aws_access_key_id: Figaro.env.aws_access_key_id,
      aws_secret_access_key: Figaro.env.aws_secret_access_key
    })
    PromotionBanner.all.each do |pb|
      if pb.banner_image.present?
        old_path = pb.promotion.banner.path.to_s
        new_path = pb.banner_image.path.to_s
        connection.copy_object(Figaro.env.aws_bucket_name, old_path, Figaro.env.aws_bucket_name, new_path)
        #connection.delete_object(Figaro.env.aws_bucket_name, old_path)
      end
    end

    remove_column :promotions, :banner
    remove_column :promotions, :target_url

  end
end
