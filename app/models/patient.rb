class Patient < ApplicationRecord
  has_many :doctor_patients, dependent: :destroy
  has_many :doctors, through: :doctor_patients
  has_many :bmr_calculations, dependent: :destroy

  validates :first_name, :last_name, :birthday, :gender, :height, :weight, presence: true
  validates :gender, inclusion: { in: %w[male female] }
  validates :height, :weight, numericality: { greater_than: 0 }

  validate :unique_name_and_birthday
  validate :birthday_cannot_be_in_future

  def age
    return nil unless birthday
    now = Time.now.utc.to_date
    now.year - birthday.year - ((now.month > birthday.month || (now.month == birthday.month && now.day >= birthday.day)) ? 0 : 1)
  end

  def full_name
    [last_name, first_name, middle_name].compact.join(' ')
  end

  private

  def unique_name_and_birthday
    return unless first_name && last_name && birthday

    existing = Patient.where(
      first_name: first_name,
      last_name: last_name,
      middle_name: middle_name,
      birthday: birthday
    ).where.not(id: id)

    errors.add(:base, 'Patient with same name and birthday already exists') if existing.exists?
  end

  def birthday_cannot_be_in_future
    return unless birthday
    
    if birthday > Date.current
      errors.add(:birthday, "can't be in the future")
    end
  end
end