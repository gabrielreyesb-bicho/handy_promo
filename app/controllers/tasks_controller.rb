# Controlador para visualización de Tareas predefinidas
# IMPORTANTE: Las tareas son globales y NO son editables por el usuario
# Solo se pueden visualizar para referencia al crear planes de trabajo
class TasksController < ApplicationController
  before_action :authenticate_user!
  before_action :admin_only!
  before_action :set_task, only: [:show]

  def index
    @tasks = Task.active.order(:name)
  end

  def show
    # Solo visualización, sin opciones de edición
  end

  private

  def set_task
    @task = Task.find(params[:id])
  end
end
