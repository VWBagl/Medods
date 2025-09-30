class DoctorsController < ApplicationController
  before_action :set_doctor, only: [:show, :update, :destroy, :patients]

  # GET /doctors
  def index
    @doctors = Doctor.all.paginate(
      page: params[:page],
      per_page: params[:per_page] || 20
    )

    render json: {
      doctors: @doctors.as_json(methods: :full_name),
      pagination: {
        current_page: @doctors.current_page,
        per_page: @doctors.per_page,
        total_entries: @doctors.total_entries,
        total_pages: @doctors.total_pages
      }
    }
  end

  # GET /doctors/1
  def show
    render json: @doctor.as_json(include: :patients, methods: :full_name)
  end

  # POST /doctors
  def create
    @doctor = Doctor.new(doctor_params)

    if @doctor.save
      render json: @doctor, status: :created
    else
      render json: { errors: @doctor.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /doctors/1
  def update
    if @doctor.update(doctor_params)
      render json: @doctor
    else
      render json: { errors: @doctor.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /doctors/1
  def destroy
    @doctor.destroy
    head :no_content
  end

  # GET /doctors/:id/patients - Получить пациентов врача
  def patients
    render json: {
      doctor: @doctor.as_json(methods: :full_name),
      patients: @doctor.patients.as_json(methods: [:age, :full_name])
    }
  end

  private

  def set_doctor
    @doctor = Doctor.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Doctor not found' }, status: :not_found
  end

  def doctor_params
    params.require(:doctor).permit(:first_name, :last_name, :middle_name)
  end
end