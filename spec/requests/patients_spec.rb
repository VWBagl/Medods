require 'swagger_helper'

RSpec.describe 'Patients API', type: :request do
  let!(:doctor1) { Doctor.create!(first_name: 'Алексей', last_name: 'Сидоров', middle_name: 'Петрович') }
  let!(:doctor2) { Doctor.create!(first_name: 'Мария', last_name: 'Иванова', middle_name: 'Сергеевна') }
  
  let!(:patient) do
    Patient.create!(
      first_name: 'Тест',
      last_name: 'Пациент',
      middle_name: 'Тестович',
      birthday: '1995-06-20',
      gender: 'male',
      height: 175,
      weight: 70,
      doctors: [doctor1, doctor2]
    )
  end

  path '/patients' do
    get 'Retrieves all patients' do
      tags 'Patients'
      produces 'application/json'
      parameter name: :page, in: :query, type: :integer, required: false, description: 'Page number'
      parameter name: :per_page, in: :query, type: :integer, required: false, description: 'Items per page'
      parameter name: :full_name, in: :query, type: :string, required: false, description: 'Search by full name'
      parameter name: :gender, in: :query, type: :string, required: false, description: 'Filter by gender'
      parameter name: :start_age, in: :query, type: :integer, required: false, description: 'Minimum age'
      parameter name: :end_age, in: :query, type: :integer, required: false, description: 'Maximum age'

      response '200', 'patients found' do
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['patients']).to be_an(Array)
          expect(data['pagination']).to be_a(Hash)
        end
      end
    end

    post 'Creates a patient' do
      tags 'Patients'
      consumes 'application/json'
      parameter name: :patient_params, in: :body, schema: {
        type: :object,
        properties: {
          patient: {
            type: :object,
            properties: {
              first_name: { type: :string, example: 'Новый' },
              last_name: { type: :string, example: 'Пациент' },
              middle_name: { type: :string, example: 'Тестович' },
              birthday: { type: :string, format: 'date', example: '1990-01-01' },
              gender: { type: :string, enum: ['male', 'female'], example: 'male' },
              height: { type: :number, example: 180 },
              weight: { type: :number, example: 75 },
              doctor_ids: { type: :array, items: { type: :integer }, example: [1, 2] }
            },
            required: ['first_name', 'last_name', 'birthday', 'gender', 'height', 'weight']
          }
        },
        required: ['patient']
      }

      response '201', 'patient created' do
        let(:patient_params) do
          {
            patient: {
              first_name: 'Уникальный',
              last_name: 'Тестовый',
              birthday: '1992-03-15',
              gender: 'male',
              height: 180,
              weight: 75
            }
          }
        end
        run_test!
      end

      response '422', 'invalid request' do
        let(:patient_params) { { patient: { first_name: nil } } }
        run_test!
      end
    end
  end

  path '/patients/{id}' do
    parameter name: :id, in: :path, type: :integer, required: true

    get 'Retrieves a patient' do
      tags 'Patients'
      produces 'application/json'

      response '200', 'patient found' do
        let(:id) { patient.id }
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['first_name']).to eq('Тест')
          expect(data['last_name']).to eq('Пациент')
        end
      end

      response '404', 'patient not found' do
        let(:id) { 99999 }
        run_test!
      end
    end

    put 'Updates a patient' do
      tags 'Patients'
      consumes 'application/json'
      parameter name: :patient_params, in: :body, schema: {
        type: :object,
        properties: {
          patient: {
            type: :object,
            properties: {
              first_name: { type: :string },
              last_name: { type: :string },
              middle_name: { type: :string },
              birthday: { type: :string, format: 'date' },
              gender: { type: :string, enum: ['male', 'female'] },
              height: { type: :number },
              weight: { type: :number },
              doctor_ids: { type: :array, items: { type: :integer } }
            }
          }
        }
      }

      response '200', 'patient updated' do
        let(:id) { patient.id }
        let(:patient_params) { { patient: { first_name: 'ОбновленноеИмя' } } }
        run_test!
      end
    end

    delete 'Deletes a patient' do
      tags 'Patients'

      response '204', 'patient deleted' do
        let(:id) { patient.id }
        run_test!
      end
    end
  end

  path '/patients/{id}/calculate_bmr' do
    parameter name: :id, in: :path, type: :integer, required: true

    post 'Calculates BMR' do
      tags 'BMR'
      consumes 'application/json'
      parameter name: :formula, in: :query, type: :string, required: true, 
                enum: ['mifflin_st_jeor', 'harris_benedict'],
                example: 'harris_benedict',
                description: 'Formula for BMR calculation'

      response '200', 'BMR calculated with Mifflin formula' do
        let(:id) { patient.id }
        let(:formula) { 'mifflin_st_jeor' }
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['bmr_calculation']['formula']).to eq('mifflin_st_jeor')
          expect(data['bmr_calculation']['result']).to be_a(Numeric)
          expect(data['patient']['full_name']).to eq('Пациент Тест Тестович')
        end
      end

      response '200', 'BMR calculated with Harris formula' do
        let(:id) { patient.id }
        let(:formula) { 'harris_benedict' }
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['bmr_calculation']['formula']).to eq('harris_benedict')
          expect(data['bmr_calculation']['result']).to be_a(Numeric)
          expect(data['patient']['full_name']).to eq('Пациент Тест Тестович')
        end
      end

      response '422', 'invalid formula' do
        let(:id) { patient.id }
        let(:formula) { 'invalid_formula' }
        run_test!
      end
    end
  end

  path '/patients/{id}/bmr_history' do
    parameter name: :id, in: :path, type: :integer, required: true

    get 'Retrieves BMR history' do
      tags 'BMR'
      produces 'application/json'
      parameter name: :page, in: :query, type: :integer, required: false
      parameter name: :per_page, in: :query, type: :integer, required: false

      response '200', 'BMR history found' do
        let(:id) { patient.id }
        before { patient.bmr_calculations.create(formula: 'mifflin_st_jeor', result: 1689.5) }
        run_test!
      end
    end
  end

  path '/patients/{id}/assign_doctors' do
    parameter name: :id, in: :path, type: :integer, required: true

    post 'Assigns doctors to patient' do
      tags 'Patient-Doctor'
      consumes 'application/json'
      parameter name: :doctor_ids_params, in: :body, schema: {
        type: :object,
        properties: {
          doctor_ids: { type: :array, items: { type: :integer }, example: [1, 2] }
        },
        required: ['doctor_ids']
      }

      response '200', 'doctors assigned' do
        let(:id) { patient.id }
        let(:doctor_ids_params) { { doctor_ids: [doctor1.id] } }
        run_test!
      end
    end
  end
end