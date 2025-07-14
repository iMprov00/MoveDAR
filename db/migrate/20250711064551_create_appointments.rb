class CreateAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :appointments do |t|
      t.string :full_name, null: false
      t.string :appointment_time, null: false
      t.date :appointment_date, null: false
      t.timestamps
    end
  end
end
