module Platform
  class DashboardPolicy < ApplicationPolicy
    def show?
      platform_admin?
    end
  end
end
