class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  
  # Associations
  belongs_to :company
  has_many :visits, dependent: :destroy
  
  # Validations
  validates :name, presence: true
  validates :email, uniqueness: { scope: :company_id }
  
  # Enums
  enum :role, {
    admin: 0,
    supervisor: 1,
    promoter: 2,
    other: 3
  }
  
  # Scopes
  scope :active_users, -> { where(active: true) }
  scope :inactive_users, -> { where(active: false) }
  scope :for_company, ->(company) { where(company: company) }
  scope :promoters, -> { where(role: :promoter) }
  
  # Methods
  def deactivate!
    update!(active: false)
  end
  
  def activate!
    update!(active: true)
  end
  
  def can_sign_in?
    active && company&.active?
  end
  
  # Override Devise method to check if user can sign in
  def active_for_authentication?
    super && can_sign_in?
  end
  
  def inactive_message
    if !active || !company&.active?
      :inactive
    else
      super
    end
  end
end
