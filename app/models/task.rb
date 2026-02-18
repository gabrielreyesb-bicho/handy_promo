class Task < ApplicationRecord
  # Validations
  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
  validates :task_type, presence: true
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :by_type, ->(type) { where(task_type: type) }
  
  # Task types enum
  TASK_TYPES = {
    photo_capture: 'photo_capture',
    image_display: 'image_display',
    comment_capture: 'comment_capture',
    incident_report: 'incident_report',
    price_update: 'price_update',
    inventory_capture: 'inventory_capture',
    planogram_display: 'planogram_display'
  }.freeze
  
  # Methods
  def deactivate!
    update!(active: false)
  end
  
  def activate!
    update!(active: true)
  end
  
  def photo_capture?
    task_type == TASK_TYPES[:photo_capture]
  end
  
  def image_display?
    task_type == TASK_TYPES[:image_display]
  end
  
  def comment_capture?
    task_type == TASK_TYPES[:comment_capture]
  end
  
  def incident_report?
    task_type == TASK_TYPES[:incident_report]
  end
  
  def inventory_capture?
    task_type == TASK_TYPES[:inventory_capture]
  end
  
  def price_update?
    task_type == TASK_TYPES[:price_update]
  end
  
  # Associations (para planes de trabajo)
  has_many :work_plan_tasks, dependent: :destroy
  has_many :work_plans, through: :work_plan_tasks
end

