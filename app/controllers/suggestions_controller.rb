class SuggestionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:update_status]
  
  def update_status
    suggestion = Suggestion.find(params[:id])
    suggestion.update!(status: params[:status])
    
    render json: { 
      id: suggestion.id,
      status: suggestion.status 
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Suggestion not found' }, status: 404
  rescue => e
    render json: { error: e.message }, status: 422
  end
end 