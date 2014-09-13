class AddIndexOidToKonachanImages < ActiveRecord::Migration
  def change
    add_index :konachan_images, :o_id, :unique => true
  end
end
