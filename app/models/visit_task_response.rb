class VisitTaskResponse < ApplicationRecord
  belongs_to :visit
  belongs_to :work_plan_task
  
  # Active Storage para fotos capturadas
  has_one_attached :photo
  
  # Validations
  validates :visit, presence: true
  validates :work_plan_task, presence: true
  validates :work_plan_task_id, uniqueness: { scope: :visit_id, message: "ya tiene una respuesta para esta visita" }
  validates :response_data, presence: true
  
  # Scopes
  scope :for_visit, ->(visit) { where(visit: visit) }
  scope :for_work_plan_task, ->(work_plan_task) { where(work_plan_task: work_plan_task) }
end
