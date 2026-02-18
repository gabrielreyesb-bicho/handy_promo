class CompanyRegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]

  # GET /resource/sign_up
  def new
    build_resource({})
    respond_with self.resource
  end

  # POST /resource
  def create
    ActiveRecord::Base.transaction do
      # Crear la compañía primero
      company_name = params[:user][:company_name]
      @company = Company.new(name: company_name, active: true)
      
      unless @company.save
        build_resource(sign_up_params)
        @company.errors.full_messages.each { |msg| resource.errors.add(:base, "Compañía: #{msg}") }
        clean_up_passwords resource
        set_minimum_password_length
        respond_with resource
        return
      end
      
      # Crear el usuario administrador asociado a la compañía
      build_resource(sign_up_params)
      resource.company = @company
      resource.role = :admin
      resource.active = true
      
      if resource.save
        if resource.active_for_authentication?
          set_flash_message! :notice, :signed_up
          sign_up(resource_name, resource)
          respond_with resource, location: after_sign_up_path_for(resource)
        else
          set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
          expire_data_after_sign_in!
          respond_with resource, location: after_inactive_sign_up_path_for(resource)
        end
      else
        clean_up_passwords resource
        set_minimum_password_length
        respond_with resource
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    clean_up_passwords resource
    set_minimum_password_length
    respond_with resource
  end

  protected

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :email, :password, :password_confirmation, :company_name])
  end

  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :email, :password, :password_confirmation, :current_password])
  end

  def sign_up_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end

  def after_sign_up_path_for(resource)
    root_path
  end
end
