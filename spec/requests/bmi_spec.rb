require 'swagger_helper'

RSpec.describe 'BMI API', type: :request do
  path '/bmi/calculate' do
    post 'Calculates BMI' do
      tags 'BMI'
      consumes 'application/json'
      parameter name: :bmi_params, in: :body, schema: {
        type: :object,
        properties: {
          weight: { type: :number, example: 75 },
          height: { type: :number, example: 180 }
        },
        required: ['weight', 'height']
      }

      response '200', 'BMI calculated' do
        let(:bmi_params) { { weight: 75, height: 180 } }
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['bmi']).to be_a(Numeric)
          expect(data['category']).to be_a(String)
        end
      end

      response '422', 'invalid parameters' do
        let(:bmi_params) { { weight: nil, height: nil } }
        run_test!
      end
    end
  end
end