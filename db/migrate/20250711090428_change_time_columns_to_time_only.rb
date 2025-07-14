class ChangeTimeColumnsToTimeOnly < ActiveRecord::Migration[8.0]
  def change
    change_column :appointments, :registration_time, :time
    change_column :appointments, :doctor_visit_time, :time
  end
end
