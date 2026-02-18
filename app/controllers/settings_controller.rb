class SettingsController < ApplicationController
  before_action :authenticate_user!
  before_action :admin_only!
  
  def show
    @company = current_company
  end
end
