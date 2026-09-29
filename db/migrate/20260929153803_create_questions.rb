class CreateQuestions < ActiveRecord::Migration[8.1]
  def change
    create_table :questions do |t|
      t.string :subject
      t.string :q_type
      t.integer :marks
      t.string :difficulty
      t.string :source
      t.text :body
      t.text :options
      t.text :answer
      t.text :solution

      t.timestamps
    end
  end
end
