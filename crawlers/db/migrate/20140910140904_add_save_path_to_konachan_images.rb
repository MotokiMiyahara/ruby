class AddSavePathToKonachanImages < ActiveRecord::Migration
  def change
    add_column :konachan_images, :save_path, :text
  end
end
