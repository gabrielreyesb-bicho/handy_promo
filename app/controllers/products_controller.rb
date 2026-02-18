# Controlador para gestión de productos
# IMPORTANTE: Todos los productos se crean y acceden solo a través de current_company
# para asegurar el aislamiento multi-tenant
class ProductsController < ApplicationController
  before_action :authenticate_user!
  before_action :admin_only!
  before_action :set_product, only: [:edit, :update, :destroy, :activate, :deactivate]

  def index
    @products = current_company.products
                                .active
                                .where.not(code: nil) # Excluir productos sin código (mandatorio)
                                .where.not(code: '') # Excluir productos con código vacío
                                .includes(:product_presentations, :product_family)
                                .order(:name)
  end

  def new
    @product = current_company.products.build
    @unit_of_measures = current_company.unit_of_measures.active.order(:name)
    @product_families = current_company.product_families.active.order(:name)
  end

  def create
    @product = current_company.products.build(product_params)
    @product.active = true
    @unit_of_measures = current_company.unit_of_measures.active.order(:name)
    @product_families = current_company.product_families.active.order(:name)
    
    # Validar que la familia pertenezca a la compañía actual
    unless current_company.product_families.exists?(@product.product_family_id)
      @product.errors.add(:product_family_id, "no pertenece a tu compañía")
      flash.now[:alert] = "Error: La familia de productos seleccionada no pertenece a tu compañía."
      render :new, status: :unprocessable_entity
      return
    end
    
    # Validar unidades de medida de las presentaciones
    @product.product_presentations.each do |presentation|
      if presentation.unit_of_measure_id.present? && !current_company.unit_of_measures.exists?(presentation.unit_of_measure_id)
        presentation.errors.add(:unit_of_measure_id, "no pertenece a tu compañía")
        @product.errors.add(:base, "Una o más presentaciones tienen unidades de medida inválidas")
      end
    end

    if @product.errors.empty? && @product.save
      redirect_to products_path, notice: "Producto creado exitosamente con #{@product.product_presentations.count} presentación(es)."
    else
      flash.now[:alert] = "Error al crear el producto: #{@product.errors.full_messages.join(', ')}"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @unit_of_measures = current_company.unit_of_measures.active.order(:name)
    @product_families = current_company.product_families.active.order(:name)
  end

  def update
    @unit_of_measures = current_company.unit_of_measures.active.order(:name)
    @product_families = current_company.product_families.active.order(:name)
    
    # Validar que la familia pertenezca a la compañía actual
    if product_params[:product_family_id] && product_params[:product_family_id].to_i != @product.product_family_id
      unless current_company.product_families.exists?(product_params[:product_family_id])
        @product.errors.add(:product_family_id, "no pertenece a tu compañía")
        flash.now[:alert] = "Error: La familia de productos seleccionada no pertenece a tu compañía."
        render :edit, status: :unprocessable_entity
        return
      end
    end
    
    # Validar unidades de medida de las presentaciones
    if product_params[:product_presentations_attributes]
      product_params[:product_presentations_attributes].each do |index, presentation_params|
        if presentation_params[:unit_of_measure_id].present? && !current_company.unit_of_measures.exists?(presentation_params[:unit_of_measure_id])
          @product.errors.add(:base, "Una o más presentaciones tienen unidades de medida inválidas")
        end
      end
    end
    
    if @product.errors.empty? && @product.update(product_params)
      redirect_to products_path, notice: "Producto actualizado exitosamente."
    else
      flash.now[:alert] = "Error al actualizar el producto: #{@product.errors.full_messages.join(', ')}"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @product.destroy
    redirect_to products_path, notice: "Producto eliminado exitosamente."
  end

  def activate
    @product.activate!
    redirect_to products_path, notice: "Producto activado exitosamente."
  end

  def deactivate
    @product.deactivate!
    redirect_to products_path, notice: "Producto desactivado exitosamente."
  end

  private

  def set_product
    @product = current_company.products.find(params[:id])
  end

  def product_params
    params.require(:product).permit(
      :code,
      :name, 
      :comments, 
      :product_family_id,
      product_presentations_attributes: [
        :id,
        :code,
        :barcode,
        :size,
        :unit_of_measure_id,
        :comments,
        :active,
        :_destroy
      ]
    )
  end
end
