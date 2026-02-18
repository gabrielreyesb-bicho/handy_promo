# Controlador API para planes de trabajo desde la app móvil
# Solo permite acceso a promotores autenticados
class Api::WorkPlansController < ApplicationController
  skip_before_action :check_promoter_web_access
  skip_before_action :verify_authenticity_token
  
  before_action :authenticate_user!
  before_action :ensure_promoter!
  before_action :set_format
  before_action :set_cors_headers

  # GET /api/work_plans/for_store/:store_id
  # Obtiene el plan de trabajo asociado al formato de una tienda
  def for_store
    store = current_user.company.stores.find(params[:store_id])
    
    # Buscar plan de trabajo para el formato de la tienda
    # Si no hay plan específico, buscar plan genérico (sin formato)
    work_plan = WorkPlan.active
                         .for_company(current_user.company)
                         .for_format(store.format)
                         .includes(work_plan_tasks: :task)
                         .first
    
    # Si no hay plan para el formato, buscar plan genérico
    work_plan ||= WorkPlan.active
                           .for_company(current_user.company)
                           .without_format
                           .includes(work_plan_tasks: :task)
                           .first
    
    if work_plan
      render json: work_plan_json(work_plan), status: :ok
    else
      render json: { error: "No hay plan de trabajo disponible para esta tienda" }, status: :not_found
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Tienda no encontrada" }, status: :not_found
  rescue => e
    Rails.logger.error "Error en API::WorkPlansController#for_store: #{e.message}"
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

  def work_plan_json(work_plan)
    {
      id: work_plan.id,
      code: work_plan.code,
      name: work_plan.name,
      description: work_plan.description,
      tasks: work_plan.work_plan_tasks.ordered.map { |wpt| work_plan_task_json(wpt) }
    }
  end

  def work_plan_task_json(work_plan_task)
    task = work_plan_task.task
    {
      id: work_plan_task.id,
      position: work_plan_task.position,
      instructions: work_plan_task.instructions,
      task: {
        id: task.id,
        code: task.code,
        name: task.name,
        description: task.description,
        task_type: task.task_type,
        icon_url: task.icon_url
      },
      image_url: work_plan_task.image.attached? ? rails_blob_url(work_plan_task.image, host: request.host_with_port, protocol: request.protocol) : nil
    }
  end
end
