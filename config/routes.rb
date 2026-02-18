Rails.application.routes.draw do
  get "visits/index"
  get "visits/new"
  get "visits/create"
  get "visits/edit"
  get "visits/update"
  get "visits/destroy"
  
  # API routes para la app móvil
  namespace :api do
    post 'sessions', to: 'sessions#create'
    delete 'sessions', to: 'sessions#destroy'
    options 'sessions', to: 'sessions#options'
    
    # Visitas - solo para promotores autenticados
    resources :visits, only: [:index, :show] do
      member do
        patch :start  # Iniciar visita (check-in)
        patch :finish # Finalizar visita (check-out)
      end
      resources :task_responses, controller: 'visit_task_responses', only: [:index, :create, :update]
    end
    
    # Planes de trabajo - solo para promotores autenticados
    get 'work_plans/for_store/:store_id', to: 'work_plans#for_store'
    
    # Productos - solo para promotores autenticados
    resources :products, only: [:index]
  end
  
  devise_for :users, controllers: {
    registrations: 'company_registrations'
  }
  
  # Usuarios - solo para administradores
  resources :users, only: [:index, :new, :create, :edit, :update, :destroy] do
    member do
      patch :activate
      patch :deactivate
    end
  end
  
  # Formatos - solo para administradores
  resources :formats, only: [:index, :new, :create, :edit, :update, :destroy] do
    member do
      patch :activate
      patch :deactivate
    end
  end
  
  # Segmentos - solo para administradores
  resources :segments, only: [:index, :new, :create, :edit, :update, :destroy] do
    member do
      patch :activate
      patch :deactivate
    end
  end
  
  # Unidades de Medida - solo para administradores
  resources :unit_of_measures, only: [:index, :new, :create, :edit, :update, :destroy] do
    member do
      patch :activate
      patch :deactivate
    end
  end
  
  # Familias de Productos - solo para administradores
  resources :product_families, only: [:index, :new, :create, :edit, :update, :destroy] do
    member do
      patch :activate
      patch :deactivate
    end
  end
  
  # Redirecciones temporales para compatibilidad (families -> product_families)
  get 'families', to: redirect('/product_families')
  get 'families/new', to: redirect('/product_families/new')
  get 'families/:id', to: redirect { |params, _req| "/product_families/#{params[:id]}" }
  get 'families/:id/edit', to: redirect { |params, _req| "/product_families/#{params[:id]}/edit" }
  
  # Productos - solo para administradores
  resources :products, only: [:index, :new, :create, :edit, :update, :destroy] do
    member do
      patch :activate
      patch :deactivate
    end
  end
  
  # Tareas - solo visualización (predefinidas, no editables)
  resources :tasks, only: [:index, :show]
  
  # Planes de Trabajo - solo para administradores
  resources :work_plans do
    member do
      patch :activate
      patch :deactivate
    end
  end
  
  # Seguimiento de Planes de Trabajo Ejecutados - solo para administradores
  resources :work_plan_executions, only: [:index, :show]
  
  # Visitas - solo para administradores
  resources :visits
  
  # Actualizaciones de Precios - solo para administradores
  resources :price_updates do
    member do
      patch :apply
      patch :cancel
    end
    collection do
      get :import
      post :process_import
      get :download_template
    end
  end
  
  # Cadenas - solo para administradores
  resources :chains, only: [:index, :new, :create, :edit, :update, :destroy] do
    member do
      patch :activate
      patch :deactivate
      get :formats
    end
  end
  
  # Redirecciones temporales para compatibilidad
  get 'chain_types', to: redirect('/formats')
  get 'chain_types/new', to: redirect('/formats/new')
  get 'chain_types/:id', to: redirect { |params, _req| "/formats/#{params[:id]}" }
  get 'chain_types/:id/edit', to: redirect { |params, _req| "/formats/#{params[:id]}/edit" }
  
  # Tiendas - solo para administradores
  resources :stores, only: [:index, :new, :create, :edit, :update, :destroy] do
    member do
      patch :activate
      patch :deactivate
    end
  end
  
  # Rutas - solo para administradores
  resources :routes, only: [:index, :new, :create, :edit, :update, :destroy] do
    member do
      patch :activate
      patch :deactivate
    end
  end
  
  # Redirecciones temporales para rutas antiguas (compatibilidad)
  get 'store_types', to: redirect('/chain_types')
  get 'store_types/new', to: redirect('/chain_types/new')
  get 'store_types/:id', to: redirect { |params, _req| "/chain_types/#{params[:id]}" }
  get 'store_types/:id/edit', to: redirect { |params, _req| "/chain_types/#{params[:id]}/edit" }
  
  # Configuración
  get 'settings', to: 'settings#show', as: :settings
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "dashboard#index"
end
