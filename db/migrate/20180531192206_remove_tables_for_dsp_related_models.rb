# frozen_string_literal: true

class RemoveTablesForDspRelatedModels < ActiveRecord::Migration
  def up
    drop_table :parsers
    drop_table :publish_jobs
    drop_table :import_jobs
    drop_table :publish_records
    drop_table :import_records
    drop_table :parameters
    drop_table :annotations
    drop_table :annotation_reports
    drop_table :import_locations
    drop_table :contents_publish_records
    drop_table :contents_repositories
    remove_column :consumer_apps, :repository_id
    remove_column :contents, :import_location_id
    remove_column :contents, :import_record_id
    remove_column :contents, :source_content_id
    remove_column :contents, :topics
    remove_column :contents, :language
    remove_column :contents, :doctype
    remove_column :contents, :copyright
    remove_column :contents, :contentsource
  end

  def down
    raise ActiveRecord::IrreversibleMigration, 'Cannot restore the DSP related tables that have been dropped'
  end
end
