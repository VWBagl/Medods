class CreateDoctorPatients < ActiveRecord::Migration[8.0]
  def change
    create_table :doctor_patients do |t|
      t.references :patient, null: false, foreign_key: true
      t.references :doctor, null: false, foreign_key: true

      t.timestamps
    end

    add_index :doctor_patients, [:patient_id, :doctor_id], unique: true
  end
end
