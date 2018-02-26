class CreateReportParams < ActiveRecord::Migration
  def change
    create_table :report_params do |t|
      t.integer :report_paramable_id
      t.string :report_paramable_type
      t.string :param_name
      t.string :param_value
      t.integer :created_by
      t.integer :updated_by

      t.timestamps null: false
    end

    add_index :report_params, [:report_paramable_type, :report_paramable_id], name: 'report_params_paramable_type_id'
  end
end
