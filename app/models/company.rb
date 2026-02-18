class Company < ApplicationRecord
  has_many :users, dependent: :restrict_with_error
  has_many :chains, dependent: :restrict_with_error
  has_many :stores, dependent: :restrict_with_error
  has_many :routes, dependent: :restrict_with_error
  has_many :segments, dependent: :restrict_with_error
  has_many :unit_of_measures, dependent: :restrict_with_error
  has_many :product_families, dependent: :restrict_with_error
  has_many :products, dependent: :restrict_with_error
  has_many :work_plans, dependent: :restrict_with_error
  has_many :price_updates, dependent: :restrict_with_error
  
  validates :name, presence: true
  
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  
  def deactivate!
    update!(active: false)
  end
  
  def activate!
    update!(active: true)
  end
end
