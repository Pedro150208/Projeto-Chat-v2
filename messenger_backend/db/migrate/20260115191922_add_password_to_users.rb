class AddPasswordToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :password, :string
  end
end
