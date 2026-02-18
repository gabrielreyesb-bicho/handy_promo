class Product < ApplicationRecord
  # Associations
  belongs_to :company
  belongs_to :product_family
  has_many :product_presentations, dependent: :destroy
  
  # Nested attributes para crear presentaciones junto con el producto
  accepts_nested_attributes_for :product_presentations, allow_destroy: true, reject_if: proc { |attrs| attrs['code'].blank? && attrs['size'].blank? && attrs['unit_of_measure_id'].blank? }
  
  # Validations
  validates :name, presence: true
  validates :name, uniqueness: { scope: :company_id }
  validates :code, presence: true
  validates :code, uniqueness: { scope: :company_id }
  validates :product_family, presence: true
  validate :must_have_at_least_one_presentation
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :for_company, ->(company) { where(company: company) }
  
  # Methods
  def deactivate!
    update!(active: false)
  end
  
  def activate!
    update!(active: true)
  end
  
  # Retorna las presentaciones activas
  def active_presentations
    product_presentations.active
  end
  
  private
  
  def must_have_at_least_one_presentation
    # Solo validar si el producto ya está guardado o si hay presentaciones siendo creadas
    if persisted? && product_presentations.empty?
      errors.add(:base, "El producto debe tener al menos una presentación")
    elsif !persisted? && product_presentations.reject(&:marked_for_destruction?).empty?
      errors.add(:base, "El producto debe tener al menos una presentación")
    end
  end
end

