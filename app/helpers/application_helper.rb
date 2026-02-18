module ApplicationHelper
  # Mostrar elemento solo si el usuario tiene el rol especificado
  def show_for_role(*roles)
    return false unless user_signed_in?
    roles.any? { |role| current_user.send("#{role}?") }
  end
  
  # Mostrar elemento solo para administradores
  def show_for_admin
    user_signed_in? && current_user.admin?
  end
  
  # Mostrar elemento solo para administradores y supervisores
  def show_for_admin_or_supervisor
    user_signed_in? && (current_user.admin? || current_user.supervisor?)
  end
  
  # Mostrar elemento solo para acceso web (no promotores)
  def show_for_web_access
    user_signed_in? && !current_user.promoter?
  end
  
  # Obtener el nombre del rol en español
  def role_name(role)
    case role.to_s
    when 'admin'
      'Administrador'
    when 'supervisor'
      'Supervisor'
    when 'promoter'
      'Promotor'
    when 'other'
      'Otro'
    else
      role.to_s.humanize
    end
  end
  
  # Badge de estado (activo/inactivo)
  def status_badge(active)
    if active
      content_tag :span, "Activo", class: "badge bg-success"
    else
      content_tag :span, "Inactivo", class: "badge bg-secondary"
    end
  end
end
