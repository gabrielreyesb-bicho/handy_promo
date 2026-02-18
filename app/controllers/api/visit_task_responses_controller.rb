# Controlador API para respuestas de tareas de visitas desde la app móvil
# Solo permite acceso a promotores autenticados
class Api::VisitTaskResponsesController < ApplicationController
  skip_before_action :check_promoter_web_access
  skip_before_action :verify_authenticity_token
  
  before_action :authenticate_user!
  before_action :ensure_promoter!
  before_action :set_format
  before_action :set_cors_headers
  before_action :set_visit
  before_action :set_work_plan_task, only: [:create, :update]

  # POST /api/visits/:visit_id/task_responses
  # Crea o actualiza una respuesta para una tarea
  def create
    response = @visit.visit_task_responses.find_or_initialize_by(
      work_plan_task_id: @work_plan_task.id
    )
    
    # Parsear response_data si viene como JSON string (multipart) o como hash (JSON)
    response_data = if params[:response_data].is_a?(String)
      JSON.parse(params[:response_data]) rescue {}
    else
      response_params[:response_data] || {}
    end
    response.response_data = response_data
    
    # Adjuntar foto si viene en el request
    if params[:photo].present?
      response.photo.attach(params[:photo])
    end
    
    if response.save
      render json: {
        id: response.id,
        visit_id: response.visit_id,
        work_plan_task_id: response.work_plan_task_id,
        response_data: response.response_data,
        photo_url: response.photo.attached? ? rails_blob_url(response.photo, only_path: false) : nil,
        created_at: response.created_at.iso8601,
        updated_at: response.updated_at.iso8601
      }, status: :created
    else
      render json: { 
        error: "Error al guardar la respuesta",
        errors: response.errors.full_messages
      }, status: :unprocessable_entity
    end
  rescue => e
    Rails.logger.error "Error en API::VisitTaskResponsesController#create: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: "Error interno del servidor" }, status: :internal_server_error
  end

  # PUT /api/visits/:visit_id/task_responses/:id
  # Actualiza una respuesta existente
  def update
    response = @visit.visit_task_responses.find(params[:id])
    
    # Parsear response_data si viene como JSON string (multipart) o como hash (JSON)
    response_data = if params[:response_data].is_a?(String)
      JSON.parse(params[:response_data]) rescue {}
    else
      response_params[:response_data] || {}
    end
    response.response_data = response_data
    
    # Adjuntar foto si viene en el request
    if params[:photo].present?
      response.photo.attach(params[:photo])
    end
    
    if response.save
      render json: {
        id: response.id,
        visit_id: response.visit_id,
        work_plan_task_id: response.work_plan_task_id,
        response_data: response.response_data,
        photo_url: response.photo.attached? ? rails_blob_url(response.photo, only_path: false) : nil,
        created_at: response.created_at.iso8601,
        updated_at: response.updated_at.iso8601
      }, status: :ok
    else
      render json: { 
        error: "Error al actualizar la respuesta",
        errors: response.errors.full_messages
      }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Respuesta no encontrada" }, status: :not_found
  rescue => e
    Rails.logger.error "Error en API::VisitTaskResponsesController#update: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: "Error interno del servidor" }, status: :internal_server_error
  end

  # GET /api/visits/:visit_id/task_responses
  # Obtiene todas las respuestas de una visita
  def index
    responses = @visit.visit_task_responses.includes(:work_plan_task)
    
    render json: responses.map { |response|
      {
        id: response.id,
        visit_id: response.visit_id,
        work_plan_task_id: response.work_plan_task_id,
        response_data: response.response_data,
        created_at: response.created_at.iso8601,
        updated_at: response.updated_at.iso8601
      }
    }, status: :ok
  rescue => e
    Rails.logger.error "Error en API::VisitTaskResponsesController#index: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: "Error interno del servidor" }, status: :internal_server_error
  end

  private

  def ensure_promoter!
    unless current_user&.promoter?
      render json: { error: "Acceso denegado. Solo promotores pueden acceder." }, status: :forbidden
    end
  end

  def set_visit
    @visit = current_user.visits.find(params[:visit_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Visita no encontrada" }, status: :not_found
  end

  def set_work_plan_task
    work_plan_task_id = response_params[:work_plan_task_id]
    unless work_plan_task_id.present?
      render json: { error: "work_plan_task_id es requerido" }, status: :bad_request
      return
    end
    @work_plan_task = WorkPlanTask.find(work_plan_task_id)
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Tarea del plan de trabajo no encontrada" }, status: :not_found
  end

  def set_format
    # Permitir JSON o multipart/form-data para fotos
    request.format = :json unless request.content_type&.include?('multipart/form-data')
  end

  def set_cors_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
    headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization'
  end

  def response_params
    # Permitir parámetros anidados o directos
    if params[:visit_task_response].present?
      params.require(:visit_task_response).permit(:work_plan_task_id, response_data: {})
    else
      # Si viene directamente en el body JSON o multipart
      params.permit(:work_plan_task_id, response_data: {})
    end
  end
end
