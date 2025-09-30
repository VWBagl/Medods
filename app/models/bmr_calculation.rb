class BmrCalculation < ApplicationRecord
  belongs_to :patient

  validates :formula, presence: true
  validates :result, numericality: { greater_than: 0 }

  # Методы расчета выносим в классовые методы
  def self.calculate_bmr(patient, formula_name)
    case formula_name.to_s.downcase
    when 'mifflin_st_jeor'
      calculate_mifflin_st_jeor(patient)
    when 'harris_benedict'
      calculate_harris_benedict(patient)
    else
      raise ArgumentError, "Unsupported formula: #{formula_name}"
    end
  end

  def self.supported_formulas
    [
      'mifflin_st_jeor',
      'harris_benedict', 
    ]
  end

  private

  def self.calculate_mifflin_st_jeor(patient)
    age = patient.age
    if patient.gender == 'male'
      (10 * patient.weight) + (6.25 * patient.height) - (5 * age) + 5
    else
      (10 * patient.weight) + (6.25 * patient.height) - (5 * age) - 161
    end
  end

  def self.calculate_harris_benedict(patient)
    age = patient.age
    if patient.gender == 'male'
      88.362 + (13.397 * patient.weight) + (4.799 * patient.height) - (5.677 * age)
    else
      447.593 + (9.247 * patient.weight) + (3.098 * patient.height) - (4.330 * age)
    end
  end
end