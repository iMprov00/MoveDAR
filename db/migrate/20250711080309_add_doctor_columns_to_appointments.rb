class AddDoctorColumnsToAppointments < ActiveRecord::Migration[8.0]
  def change
    add_column :appointments, :doctor_visited_at, :datetime
    add_column :appointments, :doctor_visit_time, :time
    add_column :appointments, :doctor_notes, :text
  end
end
