class CreateBmrCalculations < ActiveRecord::Migration[8.0]
  def change
    create_table :bmr_calculations do |t|
      t.references :patient, null: false, foreign_key: true
      t.string :formula
      t.float :result

      t.timestamps
    end
  end
end
