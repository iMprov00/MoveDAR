class AddRegisteredToAppointments < ActiveRecord::Migration[8.0]
  def change
    add_column :appointments, :registered_at, :datetime
    add_column :appointments, :registration_time, :time
  end
end
