class ChangeReportParamTypeStructure < ActiveRecord::Migration
  def change
    rename_column :report_params, :report_paramable_id, :report_id
    rename_column :report_params, :report_paramable_type, :report_param_type
    remove_index :report_params, name: 'report_params_paramable_type_id'
  end
end
