class AddNeighbor < ActiveRecord::Migration[5.0]
  def change
    add_column :figures, :nei_figures, :text, array: true, default: []
  end
end
