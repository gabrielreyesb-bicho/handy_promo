class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # Skip for API requests (mobile app)
  allow_browser versions: :modern, unless: :api_request?

  # Changes to the importmap will invalidate the etag for HTML responses
  # Note: stale_when_importmap_changes doesn't support conditional execution
  # It's safe to leave it for API requests as it only affects HTML responses
  stale_when_importmap_changes
  
  # Autenticación y autorización
  before_action :authenticate_user!, unless: :api_request?
  before_action :check_promoter_web_access, unless: :api_request?
  before_action :check_user_active, unless: :api_request?
  
  # Helpers de autorización
  helper_method :current_company, :admin?, :supervisor?, :promoter?, :can_access_web?
  
  protected
  
  # Verificar que el usuario no sea promotor (solo app móvil)
  def check_promoter_web_access
    if current_user&.promoter?
      sign_out(current_user)
      redirect_to new_user_session_path, alert: "Los promotores solo pueden acceder desde la app móvil"
    end
  end
  
  # Verificar que el usuario y su compañía estén activos
  def check_user_active
    if current_user && !current_user.active?
      sign_out(current_user)
      redirect_to new_user_session_path, alert: "Su cuenta ha sido deshabilitada"
    elsif current_user && current_user.company && !current_user.company.active?
      sign_out(current_user)
      redirect_to new_user_session_path, alert: "La compañía ha sido deshabilitada"
    end
  end
  
  # Obtener la compañía del usuario actual
  def current_company
    @current_company ||= current_user&.company
  end
  
  # Verificar si es administrador
  def admin?
    current_user&.admin?
  end
  
  # Verificar si es supervisor
  def supervisor?
    current_user&.supervisor?
  end
  
  # Verificar si es promotor
  def promoter?
    current_user&.promoter?
  end
  
  # Verificar si puede acceder a la web (no promotor)
  def can_access_web?
    current_user && !current_user.promoter?
  end
  
  # Restricción: solo administradores
  def admin_only!
    unless admin?
      redirect_to root_path, alert: "No tiene permisos para acceder a esta sección"
    end
  end
  
  # Restricción: administradores y supervisores
  def admin_or_supervisor_only!
    unless admin? || supervisor?
      redirect_to root_path, alert: "No tiene permisos para acceder a esta sección"
    end
  end
  
  # Restricción: solo acceso web (no promotores)
  def web_access_only!
    unless can_access_web?
      redirect_to root_path, alert: "Esta sección no está disponible para su rol"
    end
  end
  
  # Determinar si la petición es para la API móvil
  def api_request?
    request.path.start_with?('/api/')
  end
end
