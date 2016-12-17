class GamesController < ApplicationController

  def create
    game = Game.create(game_id: params[:id], first_turn: params[:first_turn])
    board = Board.create(game_id: game.id, width: params[:board][:width], height: params[:board][:height], figures_count: params[:board][:figures_count].to_i)
    params[:board][:figures_count].to_i.times do |i|
      Figure.create(board_id: board.id, number: i, size: params[:board][:cells].flatten.group_by{|a|a}[i].size)
    end

    render json: {status: :ok}
  end

  def show
    color = params[:color]
    game = Game.find_by(game_id: params[:id])
    board = game.board
    figures = board.figures

    figure = rand(0...board.figures_count)
    # figures.where(color: nil).order(size: :desc).each do |f|
    #
    # end



    figures.find_by(number: figure).update_attribute(:color, color)

    render json: {
      status: :ok,
      figure: figure
    }
  end

  def update
    Game.find_by(game_id: params[:id]).board.figures.find_by(number: params[:figure]).update_attribute(:color, params[:color])

    render json: {status: :ok}
  end

  def destroy
    p params
    render json: {status: :ok}
  end

end
