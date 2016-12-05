class AddS3BucketAndPrefixFieldsToImportJob < ActiveRecord::Migration
  def change
    add_column :import_jobs, :s3_bucket, :string
    add_column :import_jobs, :inbound_prefix, :string
    add_column :import_jobs, :outbound_prefix, :string
    rename_column :import_jobs, :source_path, :source_uri
  end
end
