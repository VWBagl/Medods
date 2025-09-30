class BmiController < ApplicationController
  def calculate
    # Проверяем обязательные параметры
    unless params[:weight].present? && params[:height].present?
      return render json: { error: 'Weight and height are required' }, status: :unprocessable_entity
    end

    # Всегда используем локальный расчет
    bmi_result = calculate_bmi_locally(params[:weight].to_f, params[:height].to_f)

    render json: {
      bmi: bmi_result[:bmi],
      category: bmi_result[:category],
      weight: params[:weight],
      height: params[:height],
      calculated_at: Time.current,
      message: "BMI calculated locally"
    }
  end

  private

  def calculate_bmi_locally(weight_kg, height_cm)
    height_m = height_cm / 100.0
    bmi = weight_kg / (height_m * height_m)

    category = case bmi
               when 0...18.5
                 'Underweight'
               when 18.5...25
                 'Normal weight'
               when 25...30
                 'Overweight'
               else
                 'Obesity'
               end

    { bmi: bmi.round(2), category: category }
  end
end