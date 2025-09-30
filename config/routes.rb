Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  resources :patients do
    post :calculate_bmr, on: :member
    get :bmr_history, on: :member
    
    # Новые методы для управления врачами
    post :assign_doctors, on: :member
    delete :remove_doctor, on: :member
    get :doctors, on: :member
  end

  resources :doctors do
    # Методы для управления пациентами со стороны врача
    get :patients, on: :member
  end
  
  post '/bmi/calculate', to: 'bmi#calculate'
end