class CreateGames < ActiveRecord::Migration[5.0]
  def change
    create_table :games do |t|
      t.string :game_id
      t.boolean :first_turn
    end

    create_table :boards do |t|
      t.integer :width
      t.integer :height
      t.integer :figures_count
      t.references :games
    end

    create_table :figures do |t|
      t.integer :number
      t.integer :size
      t.integer :color
    end
  end
end
