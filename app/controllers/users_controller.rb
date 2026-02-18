# Controlador para gestión de usuarios
# IMPORTANTE: Todos los usuarios se crean y acceden solo a través de current_company
# para asegurar el aislamiento multi-tenant
class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :admin_only!
  before_action :set_user, only: [:edit, :update, :destroy, :activate, :deactivate]
  
  def index
    # Recargar la asociación para evitar problemas de caché
    current_company.reload if current_company
    @users = current_company.users.active_users.order(created_at: :desc)
  end
  
  def new
    @user = current_company.users.build
  end
  
  def create
    @user = current_company.users.build(user_params)
    @user.active = true
    
    if @user.save
      redirect_to users_path, notice: "Usuario creado exitosamente."
    else
      flash.now[:alert] = "Error al crear el usuario: #{@user.errors.full_messages.join(', ')}"
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
  end
  
  def update
    # Si la contraseña está en blanco, removerla de los parámetros
    params_to_update = user_params
    if params_to_update[:password].blank?
      params_to_update = params_to_update.except(:password, :password_confirmation)
    end
    
    if @user.update(params_to_update)
      redirect_to users_path, notice: "Usuario actualizado exitosamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @user.deactivate!
    redirect_to users_path, notice: "Usuario deshabilitado exitosamente."
  end
  
  def activate
    @user.activate!
    redirect_to users_path, notice: "Usuario habilitado exitosamente."
  end
  
  def deactivate
    @user.deactivate!
    redirect_to users_path, notice: "Usuario deshabilitado exitosamente."
  end
  
  private
  
  def set_user
    @user = current_company.users.find(params[:id])
  end
  
  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :role)
  end
end
