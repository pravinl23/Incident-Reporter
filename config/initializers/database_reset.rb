# Reset suggestions on startup for clean replay experience
Rails.application.config.after_initialize do
  if Rails.env.development?
    begin
      Suggestion.destroy_all
      
      unless Incident.exists?(1)
        Incident.create!(
          id: 1,
          title: "Live Incident Replay",
          status: "active",
          severity: "SEV-1"
        )
      end
      
      Rails.logger.info "Database reset: suggestions cleared, incident ready"
      
    rescue => e
      Rails.logger.warn "Database reset failed: #{e.message}"
    end
  end
end 