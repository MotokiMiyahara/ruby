class CreateGelbooruImages < ActiveRecord::Migration
  def change
    create_table :gelbooru_images do |t|
      t.integer  :o_id, null: false
      t.text     :file_url
      t.text     :tags
      t.string   :rating
      t.string   :md5
      t.text     :save_path
      t.text     :source

      t.timestamps
    end

    add_index :gelbooru_images, :o_id, :unique => true
  end
end
