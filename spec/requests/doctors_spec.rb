require 'swagger_helper'

RSpec.describe 'Doctors API', type: :request do
  let!(:doctor) { Doctor.create!(first_name: 'Петр', last_name: 'Петров', middle_name: 'Петрович') }
  let!(:patient) do 
    Patient.create!(
      first_name: 'Иван', 
      last_name: 'Иванов', 
      birthday: '1990-05-15', 
      gender: 'male', 
      height: 180, 
      weight: 75
    )
  end

  before { doctor.patients << patient }

  path '/doctors' do
    get 'Retrieves all doctors' do
      tags 'Doctors'
      produces 'application/json'
      parameter name: :page, in: :query, type: :integer, required: false
      parameter name: :per_page, in: :query, type: :integer, required: false

      response '200', 'doctors found' do
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['doctors']).to be_an(Array)
        end
      end
    end

    post 'Creates a doctor' do
      tags 'Doctors'
      consumes 'application/json'
      parameter name: :doctor_params, in: :body, schema: {
        type: :object,
        properties: {
          doctor: {
            type: :object,
            properties: {
              first_name: { type: :string, example: 'Петр' },
              last_name: { type: :string, example: 'Петров' },
              middle_name: { type: :string, example: 'Петрович' }
            },
            required: ['first_name', 'last_name']
          }
        },
        required: ['doctor']
      }

      response '201', 'doctor created' do
        let(:doctor_params) do
          {
            doctor: {
              first_name: 'Тест',
              last_name: 'Врач'
            }
          }
        end
        run_test!
      end
    end
  end

  path '/doctors/{id}' do
    parameter name: :id, in: :path, type: :integer, required: true

    get 'Retrieves a doctor' do
      tags 'Doctors'
      produces 'application/json'

      response '200', 'doctor found' do
        let(:id) { doctor.id }
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['first_name']).to eq('Петр')
          expect(data['last_name']).to eq('Петров')
        end
      end

      response '404', 'doctor not found' do
        let(:id) { 99999 }
        run_test!
      end
    end

    put 'Updates a doctor' do
      tags 'Doctors'
      consumes 'application/json'
      parameter name: :doctor_params, in: :body, schema: {
        type: :object,
        properties: {
          doctor: {
            type: :object,
            properties: {
              first_name: { type: :string },
              last_name: { type: :string },
              middle_name: { type: :string }
            }
          }
        }
      }

      response '200', 'doctor updated' do
        let(:id) { doctor.id }
        let(:doctor_params) { { doctor: { first_name: 'ОбновленноеИмя' } } }
        run_test!
      end
    end

    delete 'Deletes a doctor' do
      tags 'Doctors'

      response '204', 'doctor deleted' do
        let(:id) { doctor.id }
        run_test!
      end
    end
  end
end