# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

platform_admin_email = ENV.fetch("PLATFORM_ADMIN_EMAIL", "admin@example.com")
platform_admin_password = ENV.fetch("PLATFORM_ADMIN_PASSWORD", "password")

User.find_or_initialize_by(email_address: platform_admin_email).tap do |user|
  user.name ||= "Platform Admin"
  user.password = platform_admin_password if user.new_record?
  user.platform_role = :platform_admin
  user.status = :active
  user.save!
end
