class Visit < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :store
  has_many :price_updates, dependent: :nullify
  has_many :visit_task_responses, dependent: :destroy
  
  # Enums
  enum :status, {
    scheduled: 0,    # Programada
    in_progress: 1,  # En curso
    completed: 2,    # Completada
    cancelled: 3     # Cancelada
  }
  
  # Validations
  validates :scheduled_date, presence: true
  validates :user, presence: true
  validates :store, presence: true
  validate :user_and_store_same_company
  validate :user_is_promoter
  
  # Scopes
  scope :for_company, ->(company) { joins(:store).where(stores: { company_id: company.id }) }
  scope :for_user, ->(user) { where(user: user) }
  scope :for_store, ->(store) { where(store: store) }
  scope :scheduled_on, ->(date) { where(scheduled_date: date) }
  scope :upcoming, -> { where('scheduled_date >= ?', Date.today).order(:scheduled_date) }
  scope :past, -> { where('scheduled_date < ?', Date.today).order(scheduled_date: :desc) }
  
  # Methods
  def scheduled?
    status == 'scheduled'
  end
  
  def in_progress?
    status == 'in_progress'
  end
  
  def completed?
    status == 'completed'
  end
  
  def cancelled?
    status == 'cancelled'
  end
  
  def status_name
    case status
    when 'scheduled'
      'Programada'
    when 'in_progress'
      'En Curso'
    when 'completed'
      'Completada'
    when 'cancelled'
      'Cancelada'
    else
      'Desconocido'
    end
  end
  
  def visit_display_name
    "#{scheduled_date.strftime("%d/%m/%Y")} - #{store.name} (#{user.name})"
  end
  
  private
  
  def user_and_store_same_company
    if user && store && user.company_id != store.company_id
      errors.add(:base, "El promotor y la tienda deben pertenecer a la misma compañía")
    end
  end
  
  def user_is_promoter
    if user && !user.promoter?
      errors.add(:user, "debe ser un promotor")
    end
  end
end
