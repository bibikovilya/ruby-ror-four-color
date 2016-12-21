class Game < ApplicationRecord
  has_one :board, dependent: :destroy
end