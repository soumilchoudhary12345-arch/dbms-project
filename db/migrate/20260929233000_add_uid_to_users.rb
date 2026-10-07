class AddUidToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :uid, :string
    add_index :users, %i[provider uid]
  end
end
