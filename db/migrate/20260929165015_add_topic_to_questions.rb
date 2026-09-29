class AddTopicToQuestions < ActiveRecord::Migration[8.1]
  def change
    add_column :questions, :topic, :string
  end
end
