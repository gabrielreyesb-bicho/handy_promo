# Controlador API para productos desde la app móvil
# Solo permite acceso a promotores autenticados
class Api::ProductsController < ApplicationController
  skip_before_action :check_promoter_web_access
  skip_before_action :verify_authenticity_token
  
  before_action :authenticate_user!
  before_action :ensure_promoter!
  before_action :set_format
  before_action :set_cors_headers

  # GET /api/products
  # Obtiene los productos activos de la compañía del usuario
  def index
    products = current_user.company.products
                            .active
                            .where.not(code: nil) # Excluir productos sin código (mandatorio)
                            .where.not(code: '') # Excluir productos con código vacío
                            .includes(:product_presentations, :product_family)
                            .order(:name)
    
    render json: products.map { |product| product_json(product) }, status: :ok
  rescue => e
    Rails.logger.error "Error en API::ProductsController#index: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: "Error interno del servidor" }, status: :internal_server_error
  end

  private

  def ensure_promoter!
    unless current_user&.promoter?
      render json: { error: "Acceso denegado. Solo promotores pueden acceder." }, status: :forbidden
    end
  end

  def set_format
    request.format = :json
  end

  def set_cors_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
    headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization'
  end

  def product_json(product)
    {
      id: product.id,
      code: product.code,
      name: product.name,
      product_family: {
        id: product.product_family.id,
        name: product.product_family.name
      },
      presentations: product.product_presentations.active.map { |presentation| presentation_json(presentation) }
    }
  end

  def presentation_json(presentation)
    {
      id: presentation.id,
      code: presentation.code,
      size: presentation.size,
      unit_of_measure: presentation.unit_of_measure ? {
        id: presentation.unit_of_measure.id,
        name: presentation.unit_of_measure.name
      } : nil,
      full_name: presentation.full_name
    }
  end
end
