class AddColoredFigures < ActiveRecord::Migration[5.0]
  def change
    add_column :boards, :colored_figures, :json, default: {}
  end
end
