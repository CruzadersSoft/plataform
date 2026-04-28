module Platform
  class ChurchPolicy < ApplicationPolicy
    def index?
      platform_admin?
    end

    def show?
      platform_admin?
    end

    def create?
      platform_admin?
    end

    def update?
      platform_admin?
    end

    class Scope < ApplicationPolicy::Scope
      def resolve
        return scope.all if user&.platform_admin?

        scope.none
      end
    end
  end
end
