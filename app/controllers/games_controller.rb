class GamesController < ApplicationController

  def create
    $redis.set(params[:id], "{first_turn: #{params[:first_turn]}, width: #{params[:board][:width]}, height: #{params[:board][:height]}, figures_count: #{params[:board][:figures_count]}}")
    $redis.set("#{params[:id]}_cells", params[:board][:cells].flatten)
    available_figures = (0...params[:board][:figures_count]).to_a
    $redis.set("#{params[:id]}_0", available_figures)
    $redis.set("#{params[:id]}_1", available_figures)
    $redis.set("#{params[:id]}_2", available_figures)
    $redis.set("#{params[:id]}_3", available_figures)

    $redis.expire(params[:id], 600)
    $redis.expire("#{params[:id]}_cells", 600)
    $redis.expire("#{params[:id]}_0", 600)
    $redis.expire("#{params[:id]}_1", 600)
    $redis.expire("#{params[:id]}_2", 600)
    $redis.expire("#{params[:id]}_3", 600)

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
    # get figures by size
    # figures.where(color: nil).order(size: :desc).each do |f|
    #   nei_colors = figures.where(number: f.nei_figures).pluck(:color).compact.uniq
    #   if nei_colors.exclude? color
    #     figure = f.number
    #     break
    #   end
    # end

    render json: {
      status: :ok,
      figure: get_figure(params[:color])
    }
  end

  def update
    fill(params[:figure], params[:color])

    p '*'*50
    p "data: #{$redis.get(params[:id])}"
    p "cells: #{$redis.get("#{params[:id]}_cells")}"
    p "0: #{$redis.get("#{params[:id]}_0")}"
    p "1: #{$redis.get("#{params[:id]}_1")}"
    p "2: #{$redis.get("#{params[:id]}_2")}"
    p "3: #{$redis.get("#{params[:id]}_3")}"
    p '*'*50

    render json: {status: :ok}
  end

  def destroy
    $redis.del params[:id]
    $redis.del "#{params[:id]}_cells"
    $redis.del "#{params[:id]}_0"
    $redis.del "#{params[:id]}_1"
    $redis.del "#{params[:id]}_2"
    $redis.del "#{params[:id]}_3"

    render json: {status: :ok}
  end

  # =================================================================

  def fill(figure, color)
    $redis.set("#{params[:id]}_#{color}", get_available_figures_for(color) - [figure.to_i])
  end

  def get_figure(color)
    get_available_figures_for(color).sample
  end

  def get_available_figures_for(color)
    data = $redis.get("#{params[:id]}_#{color}")
    data ? eval(data) : []
  end
end
