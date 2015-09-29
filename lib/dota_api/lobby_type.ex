defmodule DotaApi.LobbyType do
  @lobby_types %{
   -1 => 'Invalid',
    0 => 'Public matchmaking',
    1 => 'Practice',
    2 => 'Tournament',
    3 => 'Tutorial',
    4 => 'Co-op with bots',
    5 => 'Team match',
    6 => 'Solo Queue',
    7 => 'Ranked'
  }
  
  def get(id), do: @lobby_types[id]
end