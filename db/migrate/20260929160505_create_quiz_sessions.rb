class CreateQuizSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :quiz_sessions do |t|
      t.string :status
      t.integer :time_limit_seconds
      t.datetime :submitted_at
      t.integer :correct_count
      t.text :difficulty_mix

      t.timestamps
    end
  end
end
