class AddResolvedAtToQuestionAttempts < ActiveRecord::Migration[8.1]
  def change
    add_column :question_attempts, :resolved_at, :datetime
  end
end
