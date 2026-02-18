# Controlador para gestión de familias de productos
# IMPORTANTE: Todas las familias de productos se crean y acceden solo a través de current_company
# para asegurar el aislamiento multi-tenant
class ProductFamiliesController < ApplicationController
  before_action :authenticate_user!
  before_action :admin_only!
  before_action :set_product_family, only: [:edit, :update, :destroy, :activate, :deactivate]

  def index
    @product_families = current_company.product_families.active.order(:name)
  end

  def new
    @product_family = current_company.product_families.build
  end

  def create
    @product_family = current_company.product_families.build(product_family_params)
    @product_family.active = true

    if @product_family.save
      redirect_to product_families_path, notice: "Familia de productos creada exitosamente."
    else
      flash.now[:alert] = "Error al crear la familia de productos: #{@product_family.errors.full_messages.join(', ')}"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @product_family.update(product_family_params)
      redirect_to product_families_path, notice: "Familia de productos actualizada exitosamente."
    else
      flash.now[:alert] = "Error al actualizar la familia de productos: #{@product_family.errors.full_messages.join(', ')}"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @product_family.products.any?
      redirect_to product_families_path, alert: "No se puede eliminar la familia de productos porque tiene productos asociados."
    else
      @product_family.destroy
      redirect_to product_families_path, notice: "Familia de productos eliminada exitosamente."
    end
  end

  def activate
    @product_family.activate!
    redirect_to product_families_path, notice: "Familia de productos activada exitosamente."
  end

  def deactivate
    @product_family.deactivate!
    redirect_to product_families_path, notice: "Familia de productos desactivada exitosamente."
  end

  private

  def set_product_family
    @product_family = current_company.product_families.find(params[:id])
  end

  def product_family_params
    params.require(:product_family).permit(:name)
  end
end
