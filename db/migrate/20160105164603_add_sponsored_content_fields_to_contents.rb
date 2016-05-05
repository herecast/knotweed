class AddSponsoredContentFieldsToContents < ActiveRecord::Migration
  def up
    add_column :contents, :similar_content_overrides, :text
    add_column :contents, :banner_ad_override, :integer

    news_cat = ContentCategory.create(name:'news')
    unless ContentCategory.where(name: 'sponsored_content').exists?
      # doing this to avoid having to make parent_id mass assignable
      cc = ContentCategory.new(name: 'sponsored_content')
      cc.parent_id = news_cat.id
      cc.save
    end
  end

  def down
    remove_column :contents, :similar_content_overrides
    remove_column :contents, :banner_ad_override

    ContentCategory.find_by_name('sponsored_content').destroy
    # NOTE: not destroying news as this migration was not specifically
    # creating news, only creating it if it didn't exist so that it could
    # be the parent of sponsored_content
  end

end
