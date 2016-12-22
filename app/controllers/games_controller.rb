class GamesController < ApplicationController

  def create
    game = Game.create(game_id: params[:id], first_turn: params[:first_turn])
    board = Board.create(game_id: game.id, width: params[:board][:width], height: params[:board][:height], figures_count: params[:board][:figures_count].to_i)

    $redis.set(params[:id], "{first_turn: #{params[:first_turn]}, width: #{params[:board][:width]}, height: #{params[:board][:height]}, figures_count: #{params[:board][:figures_count]}, used_figures: [] }")

    $redis.expire(params[:id], 600)

    # calc neighbour
    # nei_hash = {}
    # arr = params[:board][:cells]
    # arr.each_with_index do |row, i|
    #   row.each_with_index do |fig_num, j|
    #     nei = []
    #     nei << arr[i-1][j-1] if i>0 && j>0
    #     nei << arr[i-1][j] if i>0
    #     nei << arr[i][j-1] if j>0
    #     nei << arr[i][j+1] if j<params[:board][:width]-1
    #     nei << arr[i+1][j-1] if i<params[:board][:height]-1 && j>0
    #     nei << arr[i+1][j] if i<params[:board][:height]-1
    #     nei_hash[fig_num] = nei.uniq - [fig_num]
    #   end
    # end

    # size calc
    # figures_att = []
    # params[:board][:figures_count].to_i.times do |i|
    #   figures_att << {board_id: board.id, number: i, size: params[:board][:cells].flatten.group_by{|a|a}[i].size}#, nei_figures: nei_hash[i])
    # end
    # Figure.create(figures_att)

    render json: {status: :ok}
  end

  def show
    color = params[:color]
    game = Game.find_by(game_id: params[:id])
    board = game.board

    figure = ((0...board.figures_count).to_a - board.colored_figures.keys.map(&:to_i)).sample

    redis_figure = get_figure params[:id]

    p '*'*50
    p "game: #{params[:id]}"
    p "db: #{figure}"
    p "data: #{$redis.get(params[:id])}"
    p "redis: #{redis_figure}"
    p '*'*50

    # get figures by size
    # figures.where(color: nil).order(size: :desc).each do |f|
    #   nei_colors = figures.where(number: f.nei_figures).pluck(:color).compact.uniq
    #   if nei_colors.exclude? color
    #     figure = f.number
    #     break
    #   end
    # end

    board.colored_figures[figure] = color
    board.save

    render json: {
      status: :ok,
      figure: figure
    }
  end

  def update
    board = Game.find_by(game_id: params[:id]).board
    board.colored_figures[params[:figure]] = params[:color]
    board.save

    fill(params[:id], params[:figure])

    render json: {status: :ok}
  end

  def destroy
    $redis.del params[:id]

    Game.find_by(game_id: params[:id]).destroy

    render json: {status: :ok}
  end

  def get_data(game_id)
    data = $redis.get(game_id)
    data ? eval(data) : {}
  end

  def save_data(game_id, data)
    $redis.set(game_id, data.to_s)
  end

  def fill(game_id, figure)
    # new_val = ($redis.keys.include?('used_figures') && $redis.get(:used_figures).present?) ? $redis.get(:used_figures) + ',' + figure.to_s : figure.to_s
    # $redis.set(:used_figures, new_val)

    data = get_data(game_id)
    data[:used_figures] << figure.to_i
    save_data(game_id, data)
  end

  def get_figure(game_id)
    data = get_data game_id
    ((0...data[:figures_count].to_i).to_a - data[:used_figures]).sample
  end
end
