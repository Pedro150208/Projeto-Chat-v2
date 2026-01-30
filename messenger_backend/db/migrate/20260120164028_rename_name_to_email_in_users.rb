class RenameNameToEmailInUsers < ActiveRecord::Migration[8.1]
  def change
    rename_column :users, :name, :email
  end
end
