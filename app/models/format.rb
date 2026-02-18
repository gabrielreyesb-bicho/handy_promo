class Format < ApplicationRecord
  # Associations
  belongs_to :chain
  has_many :stores, dependent: :restrict_with_error
  has_many :work_plans, dependent: :restrict_with_error
  
  # Validations
  validates :name, presence: true
  validates :name, uniqueness: { scope: :chain_id }
  validates :code, presence: true, allow_blank: false
  validates :code, uniqueness: { scope: :chain_id }, allow_blank: true
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :for_chain, ->(chain) { where(chain: chain) }
  
  # Methods
  def deactivate!
    update!(active: false)
  end
  
  def activate!
    update!(active: true)
  end
  
  # Helper para obtener la compañía a través de la cadena
  def company
    chain.company
  end
  
  # Helper para mostrar el nombre con la cadena
  def name_with_chain
    "#{chain.name} - #{name}"
  end
end
