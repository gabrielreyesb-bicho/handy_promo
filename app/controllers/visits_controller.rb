# Controlador para gestión de Visitas
# IMPORTANTE: Todas las visitas se crean y acceden solo a través de current_company
# para asegurar el aislamiento multi-tenant
class VisitsController < ApplicationController
  before_action :authenticate_user!
  before_action :admin_only!
  before_action :set_visit, only: [:edit, :update, :destroy]

  def index
    @visits = Visit.for_company(current_company)
                   .includes(:user, :store)
                   .order(scheduled_date: :desc, created_at: :desc)
  end

  def new
    @visit = Visit.new
    @visit.scheduled_date = Date.today
    @promoters = current_company.users.promoters.active_users.order(:name)
    @stores = current_company.stores.active.order(:name)
  end

  def create
    @visit = Visit.new(visit_params)
    @promoters = current_company.users.promoters.active_users.order(:name)
    @stores = current_company.stores.active.order(:name)
    
    # Asegurar que el usuario y la tienda pertenecen a la compañía actual
    unless @visit.user&.company_id == current_company.id
      @visit.user = nil
    end
    unless @visit.store&.company_id == current_company.id
      @visit.store = nil
    end
    
    if @visit.save
      redirect_to visits_path, notice: "Visita programada exitosamente."
    else
      flash.now[:alert] = "Error al programar la visita: #{@visit.errors.full_messages.join(', ')}"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @promoters = current_company.users.promoters.active_users.order(:name)
    @stores = current_company.stores.active.order(:name)
  end

  def update
    @promoters = current_company.users.promoters.active_users.order(:name)
    @stores = current_company.stores.active.order(:name)
    
    # Asegurar que el usuario y la tienda pertenecen a la compañía actual
    unless visit_params[:user_id].to_i.in?(current_company.users.pluck(:id))
      flash.now[:alert] = "El promotor seleccionado no pertenece a tu compañía"
      render :edit, status: :unprocessable_entity
      return
    end
    unless visit_params[:store_id].to_i.in?(current_company.stores.pluck(:id))
      flash.now[:alert] = "La tienda seleccionada no pertenece a tu compañía"
      render :edit, status: :unprocessable_entity
      return
    end
    
    if @visit.update(visit_params)
      redirect_to visits_path, notice: "Visita actualizada exitosamente."
    else
      flash.now[:alert] = "Error al actualizar la visita: #{@visit.errors.full_messages.join(', ')}"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @visit.destroy
      redirect_to visits_path, notice: "Visita eliminada exitosamente."
    else
      redirect_to visits_path, alert: "Error al eliminar la visita."
    end
  end

  private

  def set_visit
    @visit = Visit.for_company(current_company).find(params[:id])
  end

  def visit_params
    params.require(:visit).permit(:user_id, :store_id, :scheduled_date, :status)
  end
end
