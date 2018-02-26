class CreateReportJobParams < ActiveRecord::Migration
  def change
    create_table :report_job_params do |t|
      t.integer :report_job_id
      t.string :report_job_paramable_type
      t.integer :report_job_paramable_id
      t.string :param_name
      t.string :param_value
      t.integer :created_by
      t.integer :updated_by

      t.timestamps null: false
    end

    add_index :report_job_params, [:report_job_paramable_type, :report_job_paramable_id], name: 'report_job_params_paramable_type_id'
  end
end
