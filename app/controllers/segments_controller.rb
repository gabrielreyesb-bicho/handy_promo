# Controlador para gestión de segmentos
# IMPORTANTE: Todos los segmentos se crean y acceden solo a través de current_company
# para asegurar el aislamiento multi-tenant
class SegmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :admin_only!
  before_action :set_segment, only: [:edit, :update, :destroy, :activate, :deactivate]

  def index
    @segments = current_company.segments.active.order(:name)
  end

  def new
    @segment = current_company.segments.build
  end

  def create
    @segment = current_company.segments.build(segment_params)
    @segment.active = true

    if @segment.save
      redirect_to segments_path, notice: "Segmento creado exitosamente."
    else
      flash.now[:alert] = "Error al crear el segmento: #{@segment.errors.full_messages.join(', ')}"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @segment.update(segment_params)
      redirect_to segments_path, notice: "Segmento actualizado exitosamente."
    else
      flash.now[:alert] = "Error al actualizar el segmento: #{@segment.errors.full_messages.join(', ')}"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @segment.stores.any?
      redirect_to segments_path, alert: "No se puede eliminar el segmento porque tiene tiendas asignadas."
    else
      @segment.destroy
      redirect_to segments_path, notice: "Segmento eliminado exitosamente."
    end
  end

  def activate
    @segment.activate!
    redirect_to segments_path, notice: "Segmento activado exitosamente."
  end

  def deactivate
    @segment.deactivate!
    redirect_to segments_path, notice: "Segmento desactivado exitosamente."
  end

  private

  def set_segment
    @segment = current_company.segments.find(params[:id])
  end

  def segment_params
    params.require(:segment).permit(:name)
  end
end
