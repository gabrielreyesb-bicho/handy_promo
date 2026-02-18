# Controlador para gestión de formatos
# IMPORTANTE: Todos los formatos se validan para asegurar que pertenezcan
# a una cadena de current_company, garantizando el aislamiento multi-tenant
class FormatsController < ApplicationController
  before_action :authenticate_user!
  before_action :admin_only!
  before_action :set_format, only: [:edit, :update, :destroy, :activate, :deactivate]

  def index
    # Mostrar todos los formatos de todas las cadenas de la compañía
    chain_ids = current_company.chains.pluck(:id)
    @formats = Format.where(chain_id: chain_ids).active.order(created_at: :desc)
  end

  def new
    @format = Format.new
    @chains = current_company.chains.active.order(:name)
  end

  def create
    @chains = current_company.chains.active.order(:name)
    
    # Asegurar que la cadena pertenezca a la compañía actual
    chain_id = format_params[:chain_id]
    chain = current_company.chains.find_by(id: chain_id)
    
    unless chain
      @format = Format.new(format_params)
      @format.active = true
      @format.errors.add(:chain_id, "no pertenece a tu compañía")
      flash.now[:alert] = "Error: La cadena seleccionada no pertenece a tu compañía."
      render :new, status: :unprocessable_entity
      return
    end
    
    # Construir el formato a través de la cadena para asegurar la relación
    @format = chain.formats.build(format_params.except(:chain_id))
    @format.active = true

    if @format.save
      redirect_to formats_path, notice: "Formato de cadena creado exitosamente."
    else
      flash.now[:alert] = "Error al crear el formato de cadena: #{@format.errors.full_messages.join(', ')}"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @chains = current_company.chains.active.order(:name)
  end

  def update
    @chains = current_company.chains.active.order(:name)
    
    # Verificar que la cadena pertenezca a la compañía actual si se está cambiando
    new_chain_id = format_params[:chain_id]
    if new_chain_id && new_chain_id.to_i != @format.chain_id
      new_chain = current_company.chains.find_by(id: new_chain_id)
      unless new_chain
        @format.errors.add(:chain_id, "no pertenece a tu compañía")
        flash.now[:alert] = "Error: La cadena seleccionada no pertenece a tu compañía."
        render :edit, status: :unprocessable_entity
        return
      end
    end
    
    if @format.update(format_params)
      redirect_to formats_path, notice: "Formato de cadena actualizado exitosamente."
    else
      flash.now[:alert] = "Error al actualizar el formato de cadena: #{@format.errors.full_messages.join(', ')}"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @format.destroy
      redirect_to formats_path, notice: "Formato de cadena eliminado exitosamente."
  end

  def activate
    @format.activate!
      redirect_to formats_path, notice: "Formato de cadena activado exitosamente."
  end

  def deactivate
    @format.deactivate!
      redirect_to formats_path, notice: "Formato de cadena desactivado exitosamente."
  end

  private

  def set_format
    # Verificar que el formato pertenezca a una cadena de la compañía actual
    chain_ids = current_company.chains.pluck(:id)
    @format = Format.where(chain_id: chain_ids).find(params[:id])
  end

  def format_params
    params.require(:format).permit(:name, :chain_id, :comments)
  end
end
