# Controlador API para autenticación desde la app móvil
# Maneja login/logout en formato JSON
class Api::SessionsController < ApplicationController
  # Saltar todas las validaciones de ApplicationController para API
  skip_before_action :authenticate_user!
  skip_before_action :check_promoter_web_access
  skip_before_action :check_user_active
  skip_before_action :verify_authenticity_token
  
  before_action :set_format
  before_action :set_cors_headers
  
  # Permitir peticiones desde cualquier origen (solo para desarrollo)
  def set_cors_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, DELETE, OPTIONS'
    headers['Access-Control-Allow-Headers'] = 'Content-Type'
  end

  # POST /api/sessions
  def create
    # Manejar parámetros de forma segura
    email = params.dig(:user, :email) || params[:email]
    password = params.dig(:user, :password) || params[:password]
    
    unless email.present? && password.present?
      return render json: { error: "Email y contraseña son requeridos" }, status: :bad_request
    end
    
    user = User.find_for_database_authentication(email: email)
    
    if user && user.valid_password?(password) && user.active? && user.company&.active?
      sign_in(user)
      render json: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        company_id: user.company_id,
        active: user.active
      }, status: :ok
    else
      render json: { error: "Credenciales inválidas o cuenta inactiva" }, status: :unauthorized
    end
  rescue => e
    Rails.logger.error "Error en API::SessionsController#create: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: "Error interno del servidor" }, status: :internal_server_error
  end

  # DELETE /api/sessions
  def destroy
    sign_out(current_user) if user_signed_in?
    render json: { message: "Sesión cerrada" }, status: :ok
  end
  
  # OPTIONS para CORS preflight
  def options
    head :ok
  end

  private

  def set_format
    request.format = :json
  end
end
