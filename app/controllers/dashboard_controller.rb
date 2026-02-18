class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :admin_only!
  
  def index
    today = Date.today
    
    # Visitas del día actual
    @visits_today = Visit.for_company(current_company)
      .where(scheduled_date: today)
    
    @visits_scheduled = @visits_today.where(status: :scheduled).count
    @visits_completed = @visits_today.where(status: :completed).count
    @visits_pending = @visits_today.where(status: [:scheduled, :in_progress]).count
    
    # Tareas completadas hoy (respuestas de tareas ejecutadas hoy)
    @tasks_completed_today = VisitTaskResponse
      .joins(visit: :store)
      .where(stores: { company_id: current_company.id })
      .where('DATE(visit_task_responses.created_at) = ?', today)
      .count
    
    # Incidentes reportados hoy (respuestas de tareas de tipo incident_report)
    incident_report_task_ids = Task.where(task_type: Task::TASK_TYPES[:incident_report]).pluck(:id)
    @incidents_today = VisitTaskResponse
      .joins(visit: :store, work_plan_task: :task)
      .where(stores: { company_id: current_company.id })
      .where(tasks: { id: incident_report_task_ids })
      .where('DATE(visit_task_responses.created_at) = ?', today)
      .count
    
    # Actualizaciones de precios pendientes
    @price_updates_pending = current_company.price_updates.pending.count
    
    # Promotores activos hoy (usuarios con visitas programadas o completadas hoy)
    @promoters_active_today = current_company.users
      .joins(:visits)
      .where(visits: { scheduled_date: today })
      .where(role: :promoter)
      .distinct
      .count
  end
end
