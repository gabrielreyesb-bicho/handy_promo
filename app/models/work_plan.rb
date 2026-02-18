class WorkPlan < ApplicationRecord
  # Associations
  belongs_to :company
  belongs_to :format, optional: true
  has_many :work_plan_tasks, dependent: :destroy
  has_many :tasks, through: :work_plan_tasks
  
  # Nested attributes para crear work_plan_tasks junto con el plan
  accepts_nested_attributes_for :work_plan_tasks, allow_destroy: true, reject_if: proc { |attributes| attributes['task_id'].blank? }
  
  # Validations
  validates :code, presence: true
  validates :code, uniqueness: { scope: :company_id }
  validates :name, presence: true
  validates :company, presence: true
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :for_company, ->(company) { where(company: company) }
  scope :for_format, ->(format) { where(format: format) }
  scope :without_format, -> { where(format_id: nil) }
  
  # Methods
  def deactivate!
    update!(active: false)
  end
  
  def activate!
    update!(active: true)
  end
  
  # Obtener tareas ordenadas por posición
  def ordered_tasks
    tasks.order('work_plan_tasks.position')
  end
  
  # Agregar una tarea al plan
  def add_task(task, instructions: nil, data: {})
    max_position = work_plan_tasks.maximum(:position) || -1
    work_plan_tasks.create!(
      task: task,
      position: max_position + 1,
      instructions: instructions,
      data: data
    )
  end
  
  # Reordenar tareas
  def reorder_tasks(task_ids)
    task_ids.each_with_index do |task_id, index|
      work_plan_tasks.find_by(task_id: task_id)&.update(position: index)
    end
  end
end
