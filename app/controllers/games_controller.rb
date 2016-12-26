class GamesController < ApplicationController

  def create
    $redis.set(params[:id], "{first_turn: #{params[:first_turn]}, width: #{params[:board][:width]}, height: #{params[:board][:height]}, figures_count: #{params[:board][:figures_count]}}")
    $redis.set("#{params[:id]}_cells", params[:board][:cells])

    available_figures = (0...params[:board][:figures_count]).to_a
    $redis.set("#{params[:id]}_0", available_figures)
    $redis.set("#{params[:id]}_1", available_figures)
    $redis.set("#{params[:id]}_2", available_figures)
    $redis.set("#{params[:id]}_3", available_figures)

    sizes = {}
    cells = params[:board][:cells].flatten
    available_figures.each do |f|
      (sizes[cells.count(f)] ||= []) << f
    end
    $redis.set("#{params[:id]}_size", sizes)

    $redis.expire(params[:id], 600)
    $redis.expire("#{params[:id]}_cells", 600)
    $redis.expire("#{params[:id]}_size", 600)
    $redis.expire("#{params[:id]}_0", 600)
    $redis.expire("#{params[:id]}_1", 600)
    $redis.expire("#{params[:id]}_2", 600)
    $redis.expire("#{params[:id]}_3", 600)


    render json: {status: :ok}
  end

  def show
    render json: {
      status: :ok,
      figure: get_figure(params[:color])
    }
  end

  def update
    fill(params[:figure].to_i, params[:color].to_i)

    render json: {status: :ok}
  end

  def destroy
    $redis.del params[:id]
    $redis.del "#{params[:id]}_cells"
    $redis.del "#{params[:id]}_0"
    $redis.del "#{params[:id]}_1"
    $redis.del "#{params[:id]}_2"
    $redis.del "#{params[:id]}_3"
    $redis.del "#{params[:id]}_size"

    render json: {status: :ok}
  end

  # =================================================================

  def fill(figure, color)
    $redis.set("#{params[:id]}_#{color}", get_available_figures_for(color) - ([figure] + neighbor_for(figure)))
    ((0..3).to_a - [color]).each do |c|
      $redis.set("#{params[:id]}_#{c}", get_available_figures_for(c) - [figure])
    end
  end

  def get_figure(color)
    data = $redis.get("#{params[:id]}_size")
    sizes = data ? eval(data) : {}
    ava = get_available_figures_for(color)

    f = nil
    sizes.keys.sort.each do |s|
      f = (sizes[s] & ava).sample
      break if f
    end

    f || ava.sample
  end

  def get_available_figures_for(color)
    data = $redis.get("#{params[:id]}_#{color}")
    data ? eval(data) : []
  end

  def neighbor_for(figure)
    data = $redis.get("#{params[:id]}_cells")
    return [] unless data
    cells = eval(data)

    data = $redis.get(params[:id])
    return [] unless data
    width = eval(data)[:width]
    height = eval(data)[:height]

    neighbours = []
    cells.each_with_index do |row, i|
      row.each_with_index do |current_figure, j|
        if figure == current_figure
          neighbours << cells[i][j-1] if j>0
          neighbours << cells[i][j+1] if (j+1)<width
          
          neighbours << cells[i-1][j] if i>0
          neighbours << cells[i+1][j] if (i+1)<height
          
          if i%2==0
            neighbours << cells[i-1][j-1] if i>0 && j>0
            neighbours << cells[i+1][j-1] if (i+1)<height && j>0
          else
            neighbours << cells[i-1][j+1] if i>0 && (j+1)<width
            neighbours << cells[i+1][j+1] if (i+1)<height && (j+1)<width
          end
        end
      end
    end

    neighbours.compact.uniq - [figure]
  end
end
