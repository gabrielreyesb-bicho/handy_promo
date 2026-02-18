class WorkPlanTask < ApplicationRecord
  belongs_to :work_plan
  belongs_to :task
  
  # Active Storage para imágenes (usado en tareas de tipo image_display)
  has_one_attached :image
  
  # Validations
  validates :position, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  # Scopes
  scope :ordered, -> { order(:position) }
  
  # Callbacks
  before_validation :set_default_position, on: :create
  
  private
  
  def set_default_position
    if position.nil? && work_plan
      max_position = work_plan.work_plan_tasks.maximum(:position) || -1
      self.position = max_position + 1
    end
  end
end
