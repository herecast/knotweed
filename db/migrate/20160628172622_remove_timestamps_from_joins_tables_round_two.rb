class RemoveTimestampsFromJoinsTablesRoundTwo < ActiveRecord::Migration
  def up
    [:locations_organizations].each do |t|
      execute "ALTER TABLE #{t} MODIFY id INT NOT NULL"
      execute "ALTER TABLE #{t} DROP PRIMARY KEY"
      remove_column t, :id
      remove_column t, :created_at
      remove_column t, :updated_at
    end

    execute 'ALTER TABLE contacts_organizations MODIFY id INT NOT NULL'
    execute 'ALTER TABLE contacts_organizations DROP PRIMARY KEY'
    remove_column :contacts_organizations, :id

    # ensure that created_at, updated_at are set for every record
    [:annotation_reports, :annotations, :business_categories, :business_feedbacks,
     :business_locations, :business_profiles, :categories, :category_corrections,
     :channels, :comments, :consumer_apps, :contacts, :content_categories,
     :content_promotion_banner_impressions, :content_reports, :content_sets,
     :contents, :data_contexts, :datasets, :delayed_jobs, :event_instances,
     :events, :images, :import_jobs, :import_locations, :import_records,
     :issues, :listservs, :locations, :market_posts, :messages, :notifiers,
     :organizations, :parameters, :parsers, :promotion_banner_reports,
     :promotion_banners, :promotion_listservs, :promotions, :publish_jobs,
     :publish_records, :repositories, :rewrites, :roles, :schedules, :users,
     :wufoo_forms].each do |t|
       execute "update #{t} set created_at=TIMESTAMP('2000-01-01 00:00:01') where created_at is null;"
       execute "update #{t} set updated_at=TIMESTAMP('2000-01-01 00:00:01') where updated_at is null;"
     end
  end

  def down
    [:locations_organizations].each do |t|
      execute "ALTER TABLE #{t} ADD id INT PRIMARY KEY AUTO_INCREMENT"
      add_column t, :created_at, :datetime
      add_column t, :updated_at, :datetime
    end

    execute "ALTER TABLE contacts_organizations ADD id INT PRIMARY KEY AUTO_INCREMENT"
  end
end
