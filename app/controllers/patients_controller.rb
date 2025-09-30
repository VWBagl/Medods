class PatientsController < ApplicationController
  before_action :set_patient, only: 
  [:show, 
    :update, 
    :destroy, 
    :calculate_bmr, 
    :bmr_history, 
    :assign_doctors, 
    :remove_doctor, 
    :doctors]

  # GET /patients
  def index
    @q = Patient.ransack(params[:q])
    @patients = @q.result.includes(:doctors)
    
    # Фильтрация по возрасту
    if params[:start_age].present? || params[:end_age].present?
      @patients = filter_by_age(@patients, params[:start_age], params[:end_age])
    end

    # Фильтрация по ФИО
    if params[:full_name].present?
      @patients = filter_by_full_name(@patients, params[:full_name])
    end

    # Пагинация
    @patients = @patients.paginate(
      page: params[:page],
      per_page: params[:per_page] || 20
    )

    render json: {
      patients: @patients.as_json(include: :doctors, methods: [:age, :full_name]),
      pagination: {
        current_page: @patients.current_page,
        per_page: @patients.per_page,
        total_entries: @patients.total_entries,
        total_pages: @patients.total_pages
      }
    }
  end

  # GET /patients/1
  def show
    render json: @patient.as_json(include: :doctors, methods: [:age, :full_name])
  end

  # POST /patients
  def create
    @patient = Patient.new(patient_params)

    if @patient.save
      # Привязка врачей если переданы
      if params[:doctor_ids].present?
        @patient.doctor_ids = params[:doctor_ids]
      end
      
      render json: @patient, status: :created
    else
      render json: { errors: @patient.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /patients/1
  def update
    if @patient.update(patient_params)
      # Обновление врачей если переданы
      if params[:doctor_ids].present?
        @patient.doctor_ids = params[:doctor_ids]
      end
      
      render json: @patient
    else
      render json: { errors: @patient.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /patients/1
  def destroy
    @patient.destroy
    head :no_content
  end

  # POST /patients/1/calculate_bmr
def calculate_bmr
  # Проверяем что формула указана
  unless params[:formula].present?
    return render json: { 
      error: 'Formula is required',
      supported_formulas: BmrCalculation.supported_formulas 
    }, status: :unprocessable_entity
  end

  # Валидация формулы
  unless BmrCalculation.supported_formulas.include?(params[:formula].to_s.downcase)
    return render json: { 
      error: "Unsupported formula. Supported formulas: #{BmrCalculation.supported_formulas.join(', ')}" 
    }, status: :unprocessable_entity
  end

  begin
    # Расчет BMR по выбранной формуле
    bmr_result = BmrCalculation.calculate_bmr(@patient, params[:formula])
    
    # Сохраняем расчет в историю
    calculation = @patient.bmr_calculations.create!(
      formula: params[:formula],
      result: bmr_result
    )

    # Форматируем название формулы для ответа
    formula_display_name = case params[:formula].to_s.downcase
                          when 'mifflin_st_jeor'
                            'Миффлина-Сан Жеора'
                          when 'harris_benedict'
                            'Харриса-Бенедикта'
                          else
                            params[:formula]
                          end

    render json: {
      bmr_calculation: {
        id: calculation.id,
        patient_id: @patient.id,
        formula: params[:formula],
        formula_name: formula_display_name,
        result: bmr_result.round(2),
        created_at: calculation.created_at
      },
      patient: {
        id: @patient.id,
        full_name: @patient.full_name,
        age: @patient.age,
        gender: @patient.gender,
        height: @patient.height,
        weight: @patient.weight
      },
      message: "BMR рассчитан по формуле #{formula_display_name}"
    }

  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue => e
    render json: { error: "Calculation failed: #{e.message}" }, status: :unprocessable_entity
  end
end

  # GET /patients/1/bmr_history
  def bmr_history
    calculations = @patient.bmr_calculations.order(created_at: :desc)
                          .paginate(page: params[:page], per_page: params[:per_page] || 20)

    render json: {
      bmr_history: calculations.as_json,
      pagination: {
        current_page: calculations.current_page,
        per_page: calculations.per_page,
        total_entries: calculations.total_entries,
        total_pages: calculations.total_pages
      }
    }
  end

  # POST /patients/:id/assign_doctors - Назначить врачей пациенту
def assign_doctors
  unless params[:doctor_ids].present?
    return render json: { error: 'doctor_ids are required' }, status: :unprocessable_entity
  end

  # Преобразуем ID врачей в числа
  doctor_ids = params[:doctor_ids].map(&:to_i)

  # Проверяем что все врачи существуют
  existing_doctors = Doctor.where(id: doctor_ids)
  if existing_doctors.count != doctor_ids.count
    non_existent_ids = doctor_ids - existing_doctors.pluck(:id)
    return render json: { error: "Doctors with IDs #{non_existent_ids} not found" }, status: :not_found
  end

  # Назначаем врачей пациенту
  @patient.doctor_ids = doctor_ids

  if @patient.save
    render json: {
      message: "Doctors successfully assigned to patient",
      patient: @patient.as_json(include: :doctors, methods: [:age, :full_name])
    }
  else
    render json: { errors: @patient.errors.full_messages }, status: :unprocessable_entity
  end
end

# DELETE /patients/:id/remove_doctor - Удалить врача у пациента
def remove_doctor
  unless params[:doctor_id].present?
    return render json: { error: 'doctor_id is required' }, status: :unprocessable_entity
  end

  doctor = Doctor.find_by(id: params[:doctor_id])
  unless doctor
    return render json: { error: 'Doctor not found' }, status: :not_found
  end

  if @patient.doctors.delete(doctor)
    render json: {
      message: "Doctor successfully removed from patient",
      patient: @patient.as_json(include: :doctors, methods: [:age, :full_name])
    }
  else
    render json: { error: 'Failed to remove doctor from patient' }, status: :unprocessable_entity
  end
end

# GET /patients/:id/doctors - Получить врачей пациента
def doctors
  render json: {
    patient: @patient.as_json(methods: [:age, :full_name]),
    doctors: @patient.doctors.as_json(methods: :full_name)
  }
end

  private

  def set_patient
    @patient = Patient.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Patient not found' }, status: :not_found
  end

  def patient_params
    params.require(:patient).permit(
      :first_name, :last_name, :middle_name, :birthday, 
      :gender, :height, :weight
    )
  end

  def filter_by_age(patients, start_age, end_age)
    end_date = start_age.present? ? Date.current - start_age.to_i.years : Date.current
    start_date = end_age.present? ? Date.current - end_age.to_i.years : 150.years.ago

    patients.where(birthday: start_date..end_date)
  end

  def filter_by_full_name(patients, full_name_query)
    return patients if full_name_query.blank?
    
    query = full_name_query.to_s.downcase.strip
    search_terms = query.split(/\s+/).reject(&:blank?)
    
    return patients if search_terms.empty?

    conditions = []
    values = {}

    search_terms.each_with_index do |term, index|
      conditions << "(LOWER(first_name) LIKE :term#{index} OR LOWER(last_name) LIKE :term#{index} OR LOWER(middle_name) LIKE :term#{index})"
      values["term#{index}".to_sym] = "%#{term}%"
    end

    where_conditions = conditions.join(" AND ")
    patients.where(where_conditions, values)
  end
end