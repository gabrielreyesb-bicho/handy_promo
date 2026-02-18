# Controlador para seguimiento de planes de trabajo ejecutados
class WorkPlanExecutionsController < ApplicationController
  before_action :authenticate_user!
  before_action :admin_only!
  before_action :set_visit, only: [:show]
  
  def index
    # Obtener todas las visitas completadas que tienen respuestas de tareas
    # Incluir información de tienda, cadena, formato y respuestas
    @executions = Visit
      .where(status: :completed)
      .joins(:visit_task_responses)
      .joins(store: [:chain, :format])
      .where(stores: { company_id: current_company.id })
      .includes(:store, store: [:chain, :format], visit_task_responses: [work_plan_task: [:work_plan, :task]])
      .distinct
      .order(updated_at: :desc)
  end
  
  def show
    # Obtener todas las respuestas de esta visita ordenadas por posición de la tarea
    @responses = @visit.visit_task_responses
      .includes(work_plan_task: [:work_plan, :task])
      .joins(work_plan_task: :task)
      .order('work_plan_tasks.position')
    
    # Obtener el plan de trabajo de la primera respuesta
    first_response = @responses.first
    @work_plan = first_response&.work_plan_task&.work_plan
  end
  
  private
  
  def set_visit
    @visit = Visit
      .where(status: :completed)
      .joins(store: [:chain, :format])
      .where(stores: { company_id: current_company.id })
      .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to work_plan_executions_path, alert: "Visita no encontrada"
  end
end
