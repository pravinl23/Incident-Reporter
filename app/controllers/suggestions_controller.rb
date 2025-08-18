class SuggestionsController < ApplicationController
  protect_from_forgery with: :null_session
  before_action :set_suggestion

  def update_status
    @suggestion.update(status: params[:status])
    render json: { status: "ok", suggestion: @suggestion }
  end

  def accept
    @suggestion.update(accepted: true)
    render json: { status: "ok", suggestion: @suggestion }
  end

  private

  def set_suggestion
    @suggestion = Suggestion.find(params[:id])
  end
end
