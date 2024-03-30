Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  apipie

  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  devise_for :users, :controllers => {sessions: 'sessions', registrations: 'registrations'}, path: '/users', path_names: { sign_in: 'login', sign_out: 'logout', sign_up: 'join'}

  namespace :api do
    namespace :v1 do
      resources :location_types, only: [:index, :show]
      resources :machine_conditions, only: [:destroy]
      resources :machine_score_xrefs, only: [:create, :show]
      resources :machines, only: [:index, :show, :create]
      resources :operators, only: [:index, :show]
      resources :statuses, only: [:index, :show]

      resources :user_submissions, only: [:list_within_range, :location, :total_user_submission_count] do
        collection do
          get :list_within_range
          get :location
          get :total_user_submission_count
          get :top_users
        end
      end

      resources :users, only: [:auth_details, :total_user_count] do
        member do
          post :add_fave_location
          get  :list_fave_locations
          get  :profile_info
          post :remove_fave_location
        end
        collection do
          get :total_user_count
          get  :auth_details
          post :signup
          post :forgot_password
          post :resend_confirmation
        end
      end
      resources :regions, only: [:index, :show] do
        collection do
          get  :closest_by_lat_lon
          get  :does_region_exist
          get  :location_and_machine_counts
          post :suggest
          post :contact
        end
      end
      resources :location_machine_xrefs, only: [:create, :destroy, :update, :show] do
        put :ic_toggle
        collection do
          get :top_n_machines
          get :most_recent_by_lat_lon
        end
      end
      resources :location_picture_xrefs, only: [:create, :destroy, :show]
      resources :locations, only: [:index, :show, :update] do
        member do
          get :machine_details
          put :confirm
        end
        collection do
          get :closest_by_lat_lon
          get :closest_by_address
          get :within_bounding_box
          get :autocomplete
          get :autocomplete_city
          get :top_cities
          get :top_cities_by_machine
          get :type_count
          post :suggest
        end
      end

      scope 'region/:region', constraints: lambda { |request| Region.where('lower(name) = ?', request[:region].downcase).any? } do
        resources :events, only: [:index, :show]
        resources :location_machine_xrefs, only: [:index]
        resources :locations, only: [:index, :show]
        resources :machine_score_xrefs, only: [:index, :show]
        resources :operators, only: [:index]
        resources :region_link_xrefs, only: [:index, :show]
        resources :user_submissions, only: [:index, :show]
        resources :zones, only: [:index, :show]
      end
    end
  end

  get '/app' => 'pages#app'
  get '/app/support' => 'pages#app_support'
  get '/privacy' => 'pages#privacy'
  get '/faq' => 'pages#faq'
  get '/store' => 'pages#store'
  get '/donate' => 'pages#donate'
  get '.well-known/apple-app-site-association' => 'pages#apple_app_site_association'

  scope ':region', constraints: lambda { |request| Region.where('lower(name) = ?', request[:region].downcase).any? } do
    get 'app' => redirect('/app')
    get 'app/support' => redirect('/app/support')
    get 'privacy' => redirect('/privacy')
    get 'faq' => redirect('/faq')
    get 'store' => redirect('/store')
    get 'donate' => redirect('/donate')

    resources :events, only: [:index, :show]
    resources :regions, only: [:index, :show]
    get '/location_machine_xrefs/(:machine_id)', to: 'location_machine_xrefs#index', format: 'rss', :as => :lmx_rss
    resources :machine_score_xrefs, only: [:index], format: 'rss', :as => :msx_rss

    resources :pages

    get ':region' + '.rss' => 'location_machine_xrefs#index', format: 'xml'
    get ':region' + '_scores.rss' => 'machine_score_xrefs#index', format: 'xml'
    get '/robots.txt', to: 'pages#robots'

    get '/' => 'pages#region', as: 'region_homepage'
    get '/about' => 'pages#about'
    get '/contact' => 'pages#contact'
    post '/contact_sent' => 'pages#contact_sent'
    get '/links' => 'pages#links'
    get '/high_rollers' => 'pages#high_rollers'
    get '/suggest' => 'pages#suggest_new_location'
    post '/submitted_new_location' => 'pages#submitted_new_location'

    get '*page', to: 'locations#unknown_route'
  end

  resources :locations, only: [:index, :show] do
    collection do
      get :update_metadata
      get :autocomplete
      get :autocomplete_city
    end
    member do
      get :confirm
      get :render_add_machine
      get :render_update_metadata
      get :render_machine_names_for_infowindow
      get :render_machines_count
      get :render_last_updated
      get :render_location_detail
      get :render_machines
      get :render_scores
    end
  end

  resources :machines, only: [:index, :show] do
    collection do
      get :autocomplete
    end
  end

  resources :operators, only: [:autocomplete] do
    collection do
      get :autocomplete
    end
  end

  resources :location_machine_xrefs do
    collection do
      get :update_machine_condition
    end
    member do
      get :render_machine_conditions
      patch :ic_toggle
    end
  end

  resources :machine_score_xrefs
  resources :location_picture_xrefs
  resources :machine_conditions
  resources :suggested_locations, only: [] do
      member do
        post :convert_to_location
      end
  end

  resources :users, only: [:profile, :toggle_fave_location] do
    member do
      get :profile, constraints: { id: /[^\/]+/ }
      post :toggle_fave_location
    end
  end

  get 'inspire_profile' => 'pages#inspire_profile'
  get 'pages/home'
  get 'map' => 'pages#map'
  get 'operators' => 'pages#operators'
  get 'operator_location_data' => 'pages#operator_location_data'
  get 'saved' => 'pages#map', user_faved: true
  get 'map_location_data' => 'pages#map_location_data'
  get 'suggest' => 'pages#suggest_new_location', as: 'map_location_suggest'
  post 'submitted_new_location' => 'pages#submitted_new_location', as: 'map_submitted_new_location'
  get 'flier' => 'pages#flier', as: 'map_flier'

  # legacy names for regions
  get '/milwaukee' => redirect('/wisconsin')
  get '/regionless' => redirect('/map')
  get '/central-indiana' => redirect('/indiana')
  get '/mid-michigan' => redirect('/map')
  get '/burlington' => redirect('/vermont')
  get '/apps' => redirect('/app')
  get '/apps/support' => redirect('/app/support')
  get '/profile' => redirect('/inspire_profile')
  get '/twincities' => redirect('/minnesota')
  get '/maryland-north' => redirect('/baltimore')
  get '/portland-maine' => redirect('/maine')
  get '/orlando' => redirect('/florida-central')
  get '/london' => redirect('/uk')
  get '/chico' => redirect('/map')
  get '/michigan-west' => redirect('/michigan-sw')
  get '/michigan-mid' => redirect('/michigan-north')
  get '/roanoke' => redirect('/map')
  get '/redding' => redirect('/map')

  root to: 'pages#home'
end
