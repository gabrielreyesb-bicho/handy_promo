# Controlador para gestión de cadenas
# IMPORTANTE: Todas las cadenas se crean y acceden solo a través de current_company
# para asegurar el aislamiento multi-tenant
class ChainsController < ApplicationController
  before_action :authenticate_user!
  before_action :admin_only!
  before_action :set_chain, only: [:edit, :update, :destroy, :activate, :deactivate]
  before_action :set_chain_for_formats, only: [:formats]

  def index
    @chains = current_company.chains.active.order(created_at: :desc)
  end

  def new
    @chain = current_company.chains.build
  end

  def create
    @chain = current_company.chains.build(chain_params)
    @chain.active = true

    if @chain.save
      redirect_to chains_path, notice: "Cadena creada exitosamente."
    else
      flash.now[:alert] = "Error al crear la cadena: #{@chain.errors.full_messages.join(', ')}"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @chain.update(chain_params)
      redirect_to chains_path, notice: "Cadena actualizada exitosamente."
    else
      flash.now[:alert] = "Error al actualizar la cadena: #{@chain.errors.full_messages.join(', ')}"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @chain.formats.any?
      redirect_to chains_path, alert: "No se puede eliminar la cadena porque tiene formatos asociados."
    else
      @chain.destroy
      redirect_to chains_path, notice: "Cadena eliminada exitosamente."
    end
  end

  def activate
    @chain.activate!
    redirect_to chains_path, notice: "Cadena activada exitosamente."
  end

  def deactivate
    @chain.deactivate!
    redirect_to chains_path, notice: "Cadena desactivada exitosamente."
  end
  
  def formats
    @formats = @chain.formats.active.order(:name)
    respond_to do |format_type|
      format_type.json { render json: @formats.map { |f| { id: f.id, name: f.name } } }
    end
  end

  private

  def set_chain
    @chain = current_company.chains.find(params[:id])
  end
  
  def set_chain_for_formats
    @chain = current_company.chains.find(params[:id])
  end

  def chain_params
    params.require(:chain).permit(:name, :comments)
  end
end
