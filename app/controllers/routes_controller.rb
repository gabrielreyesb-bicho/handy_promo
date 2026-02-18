# Controlador para gestión de rutas
# IMPORTANTE: Todas las rutas se crean y acceden solo a través de current_company
# para asegurar el aislamiento multi-tenant
class RoutesController < ApplicationController
  before_action :authenticate_user!
  before_action :admin_only!
  before_action :set_route, only: [:edit, :update, :destroy, :activate, :deactivate]

  def index
    @routes = current_company.routes.active.order(created_at: :desc)
  end

  def new
    @route = current_company.routes.build
    @stores = current_company.stores.active.without_route.order(:name)
    @all_stores = current_company.stores.active.order(:name)
  end

  def create
    @route = current_company.routes.build(route_params)
    @route.active = true
    @all_stores = current_company.stores.active.order(:name)
    @stores = current_company.stores.active.without_route.order(:name)

    if @route.save
      # Asignar tiendas seleccionadas
      if params[:route][:store_ids].present?
        store_ids = params[:route][:store_ids].reject(&:blank?).map(&:to_i)
        stores = current_company.stores.where(id: store_ids)
        stores.update_all(route_id: @route.id)
      end
      
      redirect_to routes_path, notice: "Ruta creada exitosamente."
    else
      flash.now[:alert] = "Error al crear la ruta: #{@route.errors.full_messages.join(', ')}"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @all_stores = current_company.stores.active.order(:name)
    @stores = current_company.stores.active.order(:name)
    @selected_store_ids = @route.store_ids
  end

  def update
    @all_stores = current_company.stores.active.order(:name)
    @stores = current_company.stores.active.order(:name)
    
    if @route.update(route_params)
      # Actualizar tiendas asignadas
      if params[:route][:store_ids].present?
        new_store_ids = params[:route][:store_ids].reject(&:blank?).map(&:to_i)
        # Primero, quitar la ruta de todas las tiendas actuales de esta ruta
        @route.stores.update_all(route_id: nil)
        # Luego, asignar la ruta a las tiendas seleccionadas
        current_company.stores.where(id: new_store_ids).update_all(route_id: @route.id)
      else
        # Si no se seleccionó ninguna tienda, quitar la ruta de todas
        @route.stores.update_all(route_id: nil)
      end
      
      redirect_to routes_path, notice: "Ruta actualizada exitosamente."
    else
      @selected_store_ids = @route.store_ids
      flash.now[:alert] = "Error al actualizar la ruta: #{@route.errors.full_messages.join(', ')}"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @route.stores.any?
      redirect_to routes_path, alert: "No se puede eliminar la ruta porque tiene tiendas asignadas."
    else
      @route.destroy
      redirect_to routes_path, notice: "Ruta eliminada exitosamente."
    end
  end

  def activate
    @route.activate!
    redirect_to routes_path, notice: "Ruta activada exitosamente."
  end

  def deactivate
    @route.deactivate!
    redirect_to routes_path, notice: "Ruta desactivada exitosamente."
  end

  private

  def set_route
    @route = current_company.routes.find(params[:id])
  end

  def route_params
    params.require(:route).permit(:name, :comments)
  end
end
