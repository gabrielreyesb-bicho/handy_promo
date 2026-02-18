# Controlador para gestión de tiendas
# IMPORTANTE: Todas las tiendas se crean y acceden solo a través de current_company
# para asegurar el aislamiento multi-tenant
class StoresController < ApplicationController
  before_action :authenticate_user!
  before_action :admin_only!
  before_action :set_store, only: [:edit, :update, :destroy, :activate, :deactivate]

  def index
    @stores = current_company.stores.active.order(created_at: :desc)
  end

  def new
    @store = current_company.stores.build
    @chains = current_company.chains.active.order(:name)
    @formats = []
    @segments = current_company.segments.active.order(:name)
    @routes = current_company.routes.active.order(:name)
  end

  def create
    @store = current_company.stores.build(store_params)
    @store.active = true
    @chains = current_company.chains.active.order(:name)
    @segments = current_company.segments.active.order(:name)
    @routes = current_company.routes.active.order(:name)
    
    # Validar que la cadena y el formato pertenezcan a la compañía actual
    unless current_company.chains.exists?(@store.chain_id)
      @store.errors.add(:chain_id, "no pertenece a tu compañía")
      @formats = []
      flash.now[:alert] = "Error: La cadena seleccionada no pertenece a tu compañía."
      render :new, status: :unprocessable_entity
      return
    end
    
    chain = current_company.chains.find(@store.chain_id)
    unless chain.formats.exists?(@store.format_id)
      @store.errors.add(:format_id, "no pertenece a la cadena seleccionada")
      @formats = chain.formats.active.order(:name)
      flash.now[:alert] = "Error: El formato seleccionado no pertenece a la cadena seleccionada."
      render :new, status: :unprocessable_entity
      return
    end
    
    # Validar que el segmento pertenezca a la compañía actual si se seleccionó uno
    if @store.segment_id.present? && !current_company.segments.exists?(@store.segment_id)
      @store.errors.add(:segment_id, "no pertenece a tu compañía")
      @formats = chain.formats.active.order(:name)
      flash.now[:alert] = "Error: El segmento seleccionado no pertenece a tu compañía."
      render :new, status: :unprocessable_entity
      return
    end
    
    # Validar que la ruta pertenezca a la compañía actual si se seleccionó una
    if @store.route_id.present? && !current_company.routes.exists?(@store.route_id)
      @store.errors.add(:route_id, "no pertenece a tu compañía")
      @formats = chain.formats.active.order(:name)
      flash.now[:alert] = "Error: La ruta seleccionada no pertenece a tu compañía."
      render :new, status: :unprocessable_entity
      return
    end

    if @store.save
      redirect_to stores_path, notice: "Tienda creada exitosamente."
    else
      @formats = chain.formats.active.order(:name)
      flash.now[:alert] = "Error al crear la tienda: #{@store.errors.full_messages.join(', ')}"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @chains = current_company.chains.active.order(:name)
    @formats = @store.chain.formats.active.order(:name)
    @segments = current_company.segments.active.order(:name)
    @routes = current_company.routes.active.order(:name)
  end

  def update
    @chains = current_company.chains.active.order(:name)
    @segments = current_company.segments.active.order(:name)
    @routes = current_company.routes.active.order(:name)
    
    # Validar que la cadena y el formato pertenezcan a la compañía actual
    if store_params[:chain_id] && store_params[:chain_id].to_i != @store.chain_id
      unless current_company.chains.exists?(store_params[:chain_id])
        @store.errors.add(:chain_id, "no pertenece a tu compañía")
        @formats = []
        flash.now[:alert] = "Error: La cadena seleccionada no pertenece a tu compañía."
        render :edit, status: :unprocessable_entity
        return
      end
    end
    
    chain_id = store_params[:chain_id] || @store.chain_id
    chain = current_company.chains.find(chain_id)
    
    if store_params[:format_id] && store_params[:format_id].to_i != @store.format_id
      unless chain.formats.exists?(store_params[:format_id])
        @store.errors.add(:format_id, "no pertenece a la cadena seleccionada")
        @formats = chain.formats.active.order(:name)
        flash.now[:alert] = "Error: El formato seleccionado no pertenece a la cadena seleccionada."
        render :edit, status: :unprocessable_entity
        return
      end
    end
    
    # Validar que el segmento pertenezca a la compañía actual si se seleccionó uno
    if store_params[:segment_id].present? && store_params[:segment_id] != ""
      unless current_company.segments.exists?(store_params[:segment_id])
        @store.errors.add(:segment_id, "no pertenece a tu compañía")
        @formats = chain.formats.active.order(:name)
        flash.now[:alert] = "Error: El segmento seleccionado no pertenece a tu compañía."
        render :edit, status: :unprocessable_entity
        return
      end
    end
    
    # Validar que la ruta pertenezca a la compañía actual si se seleccionó una
    if store_params[:route_id].present? && store_params[:route_id] != ""
      unless current_company.routes.exists?(store_params[:route_id])
        @store.errors.add(:route_id, "no pertenece a tu compañía")
        @formats = chain.formats.active.order(:name)
        flash.now[:alert] = "Error: La ruta seleccionada no pertenece a tu compañía."
        render :edit, status: :unprocessable_entity
        return
      end
    end
    
    @formats = chain.formats.active.order(:name)
    
    if @store.update(store_params)
      redirect_to stores_path, notice: "Tienda actualizada exitosamente."
    else
      flash.now[:alert] = "Error al actualizar la tienda: #{@store.errors.full_messages.join(', ')}"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @store.destroy
    redirect_to stores_path, notice: "Tienda eliminada exitosamente."
  end

  def activate
    @store.activate!
    redirect_to stores_path, notice: "Tienda activada exitosamente."
  end

  def deactivate
    @store.deactivate!
    redirect_to stores_path, notice: "Tienda desactivada exitosamente."
  end

  private

  def set_store
    @store = current_company.stores.find(params[:id])
  end

  def store_params
    params.require(:store).permit(:name, :address, :latitude, :longitude, :manager_name, :manager_phone, :comments, :chain_id, :format_id, :segment_id, :visit_day, :visit_frequency, :route_id)
  end
end
