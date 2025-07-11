# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create a default incident for testing
incident = Incident.find_or_create_by!(id: 1) do |i|
  i.title = "Sample Incident - Web Tier Outage"
  i.status = "active"
  i.severity = "SEV-1"
end

puts "Created incident: #{incident.title} (ID: #{incident.id})"
