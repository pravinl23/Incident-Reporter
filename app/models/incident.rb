class Incident < ApplicationRecord
    has_many :suggestions, dependent: :destroy
end

  # app/models/suggestion.rb
  class Suggestion < ApplicationRecord
    belongs_to :incident
  end
