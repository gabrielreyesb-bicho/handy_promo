class Store < ApplicationRecord
  # Associations
  belongs_to :company
  belongs_to :chain
  belongs_to :format
  belongs_to :segment, optional: true
  belongs_to :route, optional: true
  has_many :visits, dependent: :destroy
  has_many :price_updates, dependent: :nullify
  
  # Enums
  enum :visit_frequency, {
    weekly: 0,      # Semanal
    biweekly: 1,    # Quincenal
    monthly: 2      # Mensual
  }
  
  # Validations
  validates :name, presence: true
  validates :name, uniqueness: { scope: :company_id }
  validates :chain, presence: true
  validates :format, presence: true
  # validates :segment, presence: true  # Temporalmente opcional hasta migrar datos existentes
  validates :visit_day, inclusion: { in: 0..6, message: "debe ser un día válido (0-6)" }, allow_nil: true
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :for_company, ->(company) { where(company: company) }
  scope :without_route, -> { where(route_id: nil) }
  scope :for_route, ->(route) { where(route: route) }
  
  # Methods
  def deactivate!
    update!(active: false)
  end
  
  def activate!
    update!(active: true)
  end
  
  # Helper para obtener el nombre del día de la semana
  def visit_day_name
    return nil unless visit_day
    days = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado']
    days[visit_day]
  end
  
  # Helper para obtener el nombre de la frecuencia
  def visit_frequency_name
    case visit_frequency
    when 'weekly'
      'Semanal'
    when 'biweekly'
      'Quincenal'
    when 'monthly'
      'Mensual'
    else
      'No definida'
    end
  end
end
