class PriceUpdate < ApplicationRecord
  # Associations
  belongs_to :product_presentation
  belongs_to :visit, optional: true
  belongs_to :store, optional: true
  belongs_to :company
  
  # Enums
  enum :status, {
    pending: 0,    # Pendiente de aplicar
    applied: 1,     # Aplicado
    cancelled: 2    # Cancelado
  }
  
  # Validations
  validates :new_price, presence: true, numericality: { greater_than: 0 }
  validates :product_presentation, presence: true
  validates :company, presence: true
  validate :visit_or_store_required
  validate :visit_and_store_same_company
  
  # Scopes
  scope :for_company, ->(company) { where(company: company) }
  scope :for_visit, ->(visit) { where(visit: visit) }
  scope :for_store, ->(store) { where(store: store) }
  scope :pending_for_visit, ->(visit) { where(visit: visit, status: :pending) }
  scope :pending_for_store, ->(store) { where(store: store, status: :pending) }
  
  # Methods
  def apply!
    update!(status: :applied, applied_at: Time.current)
  end
  
  def cancel!
    update!(status: :cancelled)
  end
  
  def pending?
    status == 'pending'
  end
  
  def applied?
    status == 'applied'
  end
  
  private
  
  def visit_or_store_required
    if visit_id.blank? && store_id.blank?
      errors.add(:base, "Debe especificar una visita o una tienda")
    end
  end
  
  def visit_and_store_same_company
    if visit && store && visit.store.company_id != store.company_id
      errors.add(:base, "La visita y la tienda deben pertenecer a la misma compañía")
    end
    if visit && visit.store.company_id != company_id
      errors.add(:base, "La visita debe pertenecer a la misma compañía")
    end
    if store && store.company_id != company_id
      errors.add(:base, "La tienda debe pertenecer a la misma compañía")
    end
  end
end
