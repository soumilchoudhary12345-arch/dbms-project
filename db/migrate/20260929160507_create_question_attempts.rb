class CreateQuestionAttempts < ActiveRecord::Migration[8.1]
  def change
    create_table :question_attempts do |t|
      t.references :quiz_session, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true
      t.string :answer
      t.boolean :correct

      t.timestamps
    end
  end
end
