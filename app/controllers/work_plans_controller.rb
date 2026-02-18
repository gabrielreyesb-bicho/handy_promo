# Controlador para gestión de Planes de Trabajo
# IMPORTANTE: Todos los planes de trabajo se crean y acceden solo a través de current_company
# para asegurar el aislamiento multi-tenant
class WorkPlansController < ApplicationController
  before_action :authenticate_user!
  before_action :admin_only!
  before_action :set_work_plan, only: [:show, :edit, :update, :destroy, :activate, :deactivate]

  def index
    @work_plans = current_company.work_plans.active.includes(:tasks).order(:name)
  end

  def show
    @work_plan_tasks = @work_plan.work_plan_tasks.includes(:task).ordered
  end

  def new
    @work_plan = current_company.work_plans.build
    @available_tasks = Task.active.order(:name)
    @available_chains = current_company.chains.active.order(:name)
    @available_formats = Format.joins(chain: :company)
                               .where(companies: { id: current_company.id })
                               .where(active: true)
                               .includes(:chain)
                               .order('chains.name, formats.name')
  end

  def create
    @work_plan = current_company.work_plans.build(work_plan_params)
    @work_plan.active = true
    @available_tasks = Task.active.order(:name)
    
    Rails.logger.info "=== CREANDO PLAN DE TRABAJO ==="
    Rails.logger.info "Parámetros raw: #{params[:work_plan].inspect}"
    
    # Verificar work_plan_tasks_attributes
    if params[:work_plan] && params[:work_plan][:work_plan_tasks_attributes]
      params[:work_plan][:work_plan_tasks_attributes].each do |index, attrs|
        Rails.logger.info "  Task #{index}: task_id=#{attrs[:task_id]}, image=#{attrs[:image].present? ? 'PRESENTE' : 'AUSENTE'}"
        if attrs[:image].present?
          Rails.logger.info "    Image filename: #{attrs[:image].original_filename rescue 'N/A'}"
        end
      end
    end
    
    if @work_plan.save
      Rails.logger.info "=== RESULTADO DESPUÉS DE CREATE ==="
      @work_plan.work_plan_tasks.each do |wpt|
        if wpt.image.attached?
          Rails.logger.info "WorkPlanTask #{wpt.id} tiene imagen: #{wpt.image.filename}"
        else
          Rails.logger.info "WorkPlanTask #{wpt.id} NO tiene imagen"
        end
      end
      
      redirect_to work_plan_path(@work_plan), notice: "Plan de trabajo creado exitosamente."
    else
      Rails.logger.error "Error al crear plan: #{@work_plan.errors.full_messages.join(', ')}"
      flash.now[:alert] = "Error al crear el plan de trabajo: #{@work_plan.errors.full_messages.join(', ')}"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @available_tasks = Task.active.order(:name)
    @work_plan_tasks = @work_plan.work_plan_tasks.includes(:task).ordered
    @available_chains = current_company.chains.active.order(:name)
    @available_formats = Format.joins(chain: :company)
                               .where(companies: { id: current_company.id })
                               .where(active: true)
                               .includes(:chain)
                               .order('chains.name, formats.name')
  end

  def update
    @available_tasks = Task.active.order(:name)
    @work_plan_tasks = @work_plan.work_plan_tasks.includes(:task).ordered
    
    Rails.logger.info "=== ACTUALIZANDO PLAN DE TRABAJO ==="
    Rails.logger.info "Plan ID: #{@work_plan.id}"
    Rails.logger.info "Parámetros raw: #{params[:work_plan].inspect}"
    
    # Verificar work_plan_tasks_attributes
    if params[:work_plan] && params[:work_plan][:work_plan_tasks_attributes]
      params[:work_plan][:work_plan_tasks_attributes].each do |index, attrs|
        Rails.logger.info "  Task #{index}: task_id=#{attrs[:task_id]}, id=#{attrs[:id]}, image=#{attrs[:image].present? ? 'PRESENTE' : 'AUSENTE'}"
        if attrs[:image].present?
          Rails.logger.info "    Image filename: #{attrs[:image].original_filename rescue 'N/A'}"
          Rails.logger.info "    Image content_type: #{attrs[:image].content_type rescue 'N/A'}"
        end
      end
    end
    
    Rails.logger.info "Parámetros permitidos: #{work_plan_params.inspect}"
    
    if @work_plan.update(work_plan_params)
      # Verificar que las imágenes se hayan guardado
      Rails.logger.info "=== RESULTADO DESPUÉS DE UPDATE ==="
      @work_plan.work_plan_tasks.each do |wpt|
        if wpt.image.attached?
          Rails.logger.info "WorkPlanTask #{wpt.id} tiene imagen: #{wpt.image.filename}"
        else
          Rails.logger.info "WorkPlanTask #{wpt.id} NO tiene imagen"
        end
      end
      
      redirect_to work_plan_path(@work_plan), notice: "Plan de trabajo actualizado exitosamente."
    else
      Rails.logger.error "Error al actualizar plan: #{@work_plan.errors.full_messages.join(', ')}"
      Rails.logger.error "Errores detallados: #{@work_plan.errors.details.inspect}"
      flash.now[:alert] = "Error al actualizar el plan de trabajo: #{@work_plan.errors.full_messages.join(', ')}"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @work_plan.destroy
      redirect_to work_plans_path, notice: "Plan de trabajo eliminado exitosamente."
    else
      redirect_to work_plans_path, alert: "Error al eliminar el plan de trabajo."
    end
  end

  def activate
    @work_plan.activate!
    redirect_to work_plans_path, notice: "Plan de trabajo activado."
  end

  def deactivate
    @work_plan.deactivate!
    redirect_to work_plans_path, notice: "Plan de trabajo desactivado."
  end

  private

  def set_work_plan
    @work_plan = current_company.work_plans.find(params[:id])
  end

  def work_plan_params
    params.require(:work_plan).permit(
      :code, 
      :name, 
      :description,
      :format_id,
      work_plan_tasks_attributes: [
        :id,
        :task_id,
        :position,
        :instructions,
        :image,
        :_destroy
      ]
    )
  end
end
