module Platform
  class DashboardController < ApplicationController
    skip_before_action :require_current_church

    def show
      authorize :dashboard, policy_class: Platform::DashboardPolicy
    end
  end
end
