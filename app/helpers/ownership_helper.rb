module OwnershipHelper
  def owned_by?(user)
    self.user_id == user.id
  end
end
