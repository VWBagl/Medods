class Doctor < ApplicationRecord
  has_many :doctor_patients, dependent: :destroy
  has_many :patients, through: :doctor_patients

  validates :first_name, :last_name, presence: true

  def full_name
    [last_name, first_name, middle_name].compact.join(' ')
  end
end