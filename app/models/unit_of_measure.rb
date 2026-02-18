class UnitOfMeasure < ApplicationRecord
  # Associations
  belongs_to :company
  has_many :products, dependent: :restrict_with_error
  
  # Validations
  validates :name, presence: true
  validates :name, uniqueness: { scope: :company_id }
  
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
end
