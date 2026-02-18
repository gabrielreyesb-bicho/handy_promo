# Controlador para gestión de unidades de medida
# IMPORTANTE: Todas las unidades de medida se crean y acceden solo a través de current_company
# para asegurar el aislamiento multi-tenant
class UnitOfMeasuresController < ApplicationController
  before_action :authenticate_user!
  before_action :admin_only!
  before_action :set_unit_of_measure, only: [:edit, :update, :destroy, :activate, :deactivate]

  def index
    @unit_of_measures = current_company.unit_of_measures.active.order(:name)
  end

  def new
    @unit_of_measure = current_company.unit_of_measures.build
  end

  def create
    @unit_of_measure = current_company.unit_of_measures.build(unit_of_measure_params)
    @unit_of_measure.active = true

    if @unit_of_measure.save
      redirect_to unit_of_measures_path, notice: "Unidad de medida creada exitosamente."
    else
      flash.now[:alert] = "Error al crear la unidad de medida: #{@unit_of_measure.errors.full_messages.join(', ')}"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @unit_of_measure.update(unit_of_measure_params)
      redirect_to unit_of_measures_path, notice: "Unidad de medida actualizada exitosamente."
    else
      flash.now[:alert] = "Error al actualizar la unidad de medida: #{@unit_of_measure.errors.full_messages.join(', ')}"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @unit_of_measure.products.any?
      redirect_to unit_of_measures_path, alert: "No se puede eliminar la unidad de medida porque tiene productos asociados."
    else
      @unit_of_measure.destroy
      redirect_to unit_of_measures_path, notice: "Unidad de medida eliminada exitosamente."
    end
  end

  def activate
    @unit_of_measure.activate!
    redirect_to unit_of_measures_path, notice: "Unidad de medida activada exitosamente."
  end

  def deactivate
    @unit_of_measure.deactivate!
    redirect_to unit_of_measures_path, notice: "Unidad de medida desactivada exitosamente."
  end

  private

  def set_unit_of_measure
    @unit_of_measure = current_company.unit_of_measures.find(params[:id])
  end

  def unit_of_measure_params
    params.require(:unit_of_measure).permit(:name)
  end
end
