# Controlador API para visitas desde la app móvil
# Solo permite acceso a promotores autenticados
class Api::VisitsController < ApplicationController
  skip_before_action :check_promoter_web_access
  skip_before_action :verify_authenticity_token
  
  before_action :authenticate_user!
  before_action :ensure_promoter!
  before_action :set_format
  before_action :set_cors_headers

  # GET /api/visits
  # Obtiene las visitas del usuario promotor para el día actual
  # Devuelve visitas programadas, en progreso y completadas (no canceladas)
  def index
    date = params[:date].present? ? Date.parse(params[:date]) : Date.today
    
    visits = current_user.visits
                         .scheduled_on(date)
                         .where(status: [:scheduled, :in_progress, :completed]) # Incluir completadas
                         .includes(:store, store: [:chain, :format])
                         .order(:scheduled_date, :created_at)
    
    render json: visits.map { |visit| visit_json(visit) }, status: :ok
  rescue Date::Error
    render json: { error: "Fecha inválida" }, status: :bad_request
  rescue => e
    Rails.logger.error "Error en API::VisitsController#index: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: "Error interno del servidor" }, status: :internal_server_error
  end

  # GET /api/visits/:id
  def show
    visit = current_user.visits.find(params[:id])
    render json: visit_json(visit), status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Visita no encontrada" }, status: :not_found
  rescue => e
    Rails.logger.error "Error en API::VisitsController#show: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: "Error interno del servidor" }, status: :internal_server_error
  end

  # PATCH /api/visits/:id/start
  # Inicia una visita (check-in)
  def start
    visit = current_user.visits.find(params[:id])
    
    Rails.logger.info "Intentando iniciar visita ID: #{visit.id}, Estado actual: #{visit.status} (#{visit.status_name})"
    
    # Verificar que no haya otra visita en progreso del mismo día
    active_visit = current_user.visits
                                .in_progress
                                .where.not(id: visit.id)
                                .where(scheduled_date: visit.scheduled_date)
                                .first
    if active_visit
      Rails.logger.warn "Usuario tiene otra visita en progreso del mismo día: #{active_visit.id}"
      render json: { 
        error: "Ya tienes una visita en progreso para hoy. Por favor finaliza la visita a #{active_visit.store.name} antes de iniciar otra." 
      }, status: :unprocessable_entity
      return
    end
    
    # Permitir iniciar visitas programadas o reiniciar visitas en progreso
    if visit.scheduled? || visit.in_progress?
      if visit.scheduled?
        visit.update!(status: :in_progress)
        Rails.logger.info "Visita #{visit.id} iniciada exitosamente"
      else
        Rails.logger.info "Visita #{visit.id} ya está en progreso, continuando"
      end
      # Recargar la visita para obtener el estado actualizado
      visit.reload
      render json: visit_json(visit), status: :ok
    else
      Rails.logger.warn "Intento de iniciar visita #{visit.id} con estado inválido: #{visit.status} (#{visit.status_name})"
      render json: { 
        error: "Solo se pueden iniciar visitas programadas. Estado actual: #{visit.status_name}" 
      }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Visita no encontrada" }, status: :not_found
  rescue => e
    Rails.logger.error "Error en API::VisitsController#start: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: "Error interno del servidor" }, status: :internal_server_error
  end

  # PATCH /api/visits/:id/finish
  # Finaliza una visita (check-out)
  def finish
    visit = current_user.visits.find(params[:id])
    
    Rails.logger.info "Intentando finalizar visita ID: #{visit.id}, Estado actual: #{visit.status} (#{visit.status_name})"
    
    # Solo permitir finalizar visitas en progreso
    if visit.in_progress?
      visit.update!(status: :completed)
      Rails.logger.info "Visita #{visit.id} finalizada exitosamente"
      # Recargar la visita para obtener el estado actualizado
      visit.reload
      render json: visit_json(visit), status: :ok
    else
      Rails.logger.warn "Intento de finalizar visita #{visit.id} con estado inválido: #{visit.status} (#{visit.status_name})"
      render json: { 
        error: "Solo se pueden finalizar visitas en progreso. Estado actual: #{visit.status_name}" 
      }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Visita no encontrada" }, status: :not_found
  rescue => e
    Rails.logger.error "Error en API::VisitsController#finish: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: "Error interno del servidor" }, status: :internal_server_error
  end

  private

  def ensure_promoter!
    unless current_user&.promoter?
      render json: { error: "Acceso denegado. Solo promotores pueden acceder." }, status: :forbidden
    end
  end

  def set_format
    request.format = :json
  end

  def set_cors_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
    headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization'
  end

  def visit_json(visit)
    {
      id: visit.id,
      scheduled_date: visit.scheduled_date.to_s, # Formato ISO: "YYYY-MM-DD"
      status: visit.status,
      status_name: visit.status_name,
      store: {
        id: visit.store.id,
        name: visit.store.name,
        address: visit.store.address,
        chain: {
          id: visit.store.chain.id,
          name: visit.store.chain.name
        },
        format: {
          id: visit.store.format.id,
          name: visit.store.format.name
        }
      },
      created_at: visit.created_at.iso8601,
      updated_at: visit.updated_at.iso8601
    }
  end
end
