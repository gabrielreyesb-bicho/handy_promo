class ProductPresentation < ApplicationRecord
  # Associations
  belongs_to :product
  belongs_to :unit_of_measure
  
  # Validations
  validates :code, presence: true
  validates :code, uniqueness: { scope: :product_id }
  validates :barcode, uniqueness: true, allow_nil: true
  validates :unit_of_measure, presence: true
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  
  # Methods
  def deactivate!
    update!(active: false)
  end
  
  def activate!
    update!(active: true)
  end
  
  # Retorna el tamaño formateado con su unidad de medida
  def formatted_size
    return unit_of_measure.name if size.nil?
    "#{size.to_i == size ? size.to_i : size} #{unit_of_measure.name}"
  end
  
  # Retorna solo el tamaño sin la unidad
  def size_display
    return nil if size.nil?
    size.to_i == size ? size.to_i : size
  end
  
  # Retorna el nombre completo: código + tamaño
  def full_name
    size_str = formatted_size
    "#{code} (#{size_str})"
  end
  
  # Retorna el nombre completo con el producto: Producto - Código (Tamaño)
  def full_name_with_product
    "#{product.name} - #{full_name}"
  end
end
