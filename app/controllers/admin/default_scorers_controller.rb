# frozen_string_literal: true

module Admin
  class DefaultScorersController < Admin::AdminController
    before_action :set_scorer, only: %i[show edit update]

    def index
      @scorers = DefaultScorer.all
    end

    def show; end

    def new
      @scorer = DefaultScorer.new
    end

    def create
      @scorer = DefaultScorer.new scorer_params

      if @scorer.save
        Analytics::Tracker.track_default_scorer_created_event current_user, @scorer
        redirect_to admin_default_scorer_path(@scorer)
      else
        render action: :new
      end
    rescue ActiveRecord::SerializationTypeMismatch
      # Get a version of the params without the scale, which is causing
      # the Exception to be raised.
      sanitized_params = scorer_params
      sanitized_params.delete(:scale)
      sanitized_params.delete('scale')

      # Reinitialize the object without the scale, to maintain the
      # passed values, just in case another error should be communicated
      # back to the caller.
      @scorer = DefaultScorer.new sanitized_params
      @scorer.errors.add(:scale, :type)

      render action: :new
    end

    def edit; end

    def update
      if @scorer.update scorer_params
        Analytics::Tracker.track_default_scorer_updated_event current_user, @scorer
        redirect_to admin_default_scorer_path(@scorer)
      else
        render action: :edit
      end
    rescue ActiveRecord::SerializationTypeMismatch
      @scorer.reload

      # Get a version of the params without the scale, which is causing
      # the Exception to be raised.
      sanitized_params = scorer_params
      sanitized_params.delete(:scale)
      sanitized_params.delete('scale')

      # Re-update the object without the scale, to maintain the
      # passed values, just in case another error should be communicated
      # back to the caller.
      @scorer.update sanitized_params
      @scorer.errors.add(:scale, :type)

      render action: :edit
    end

    private

    def scorer_params
      return unless params[:default_scorer]

      params.require(:default_scorer).permit(
        :code,
        :name,
        :manual_max_score,
        :manual_max_score_value,
        :show_scale_labels,
        :scale_list,
        :scale,
        :state,
        scale: []
      ).tap do |whitelisted|
        whitelisted[:scale_with_labels] = params[:default_scorer][:scale_with_labels]
      end
    end

    def set_scorer
      @scorer = DefaultScorer.where(id: params[:id]).first

      render json: { error: 'Not Found!' }, status: :not_found unless @scorer
    end
  end
end
