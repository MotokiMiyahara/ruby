class CreateKonachanImages < ActiveRecord::Migration
  def change
    create_table :konachan_images do |t|
      t.integer :o_id, :null => false
      t.text :file_url
      t.text :tags
      t.string :rating
      t.string :md5

      t.timestamps
    end
  end
end
