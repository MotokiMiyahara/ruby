class AddSourceToKonachanImages < ActiveRecord::Migration
  def change
    add_column :konachan_images, :source, :text
  end
end
