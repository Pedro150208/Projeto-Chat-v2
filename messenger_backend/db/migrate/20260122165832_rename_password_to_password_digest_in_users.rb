class RenamePasswordToPasswordDigestInUsers < ActiveRecord::Migration[8.1]
  def change
    rename_column :users, :password, :password_digest
  end
end
