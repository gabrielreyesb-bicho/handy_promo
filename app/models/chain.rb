class Chain < ApplicationRecord
  # Associations
  belongs_to :company
  has_many :formats, dependent: :restrict_with_error
  has_many :stores, dependent: :restrict_with_error
  
  # Validations
  validates :name, presence: true
  validates :name, uniqueness: { scope: :company_id }
  validates :code, presence: true, allow_blank: false
  validates :code, uniqueness: { scope: :company_id }, allow_blank: true
  
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
