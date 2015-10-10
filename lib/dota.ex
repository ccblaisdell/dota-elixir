defmodule Dota do
  alias Dota.Steam
  alias Dota.Dotabuff

  @steam_id_diff 76561197960265728

  ## Client API

  # Returns a single match in full detail
  def match(match_id) do
    details = Steam.fetch("GetMatchDetails", %{match_id: match_id}) 
    case details do
      {:error, reason} -> details
      _ -> {:ok, details}
    end
  end

  # Returns a list of match summaries
  def history(account_id) do
    summaries = Steam.fetch("GetMatchHistory", %{account_id: account_id})
    case summaries do
      {:error, reason} -> summaries
      _ -> {:ok, summaries}
    end
  end

  def p_matches(ids) do
    ids
    |> Enum.map(&async_match/1)
    |> Enum.map(&await_match/1)
  end

  defp async_match(id), do: Task.async(fn -> match(id) end)

  defp await_match(task) do
    {:ok, details} = Task.await(task)
    IO.inspect "Fetched match: #{details["match_id"]}"
    details
  end

  def profiles(ids) do
    profiles = Steam.fetch("GetPlayerSummaries", %{steamids: Enum.join(ids, ",")},
                            "ISteamUser", "v0002")
    {:ok, profiles}
  end

  def profile(id) do
    {:ok, [profile | _]} = profiles([id])
    {:ok, profile}
  end

  def friends(id) do
    profiles = Steam.fetch("GetFriendList", %{steamid: id}, "ISteamUser") 
    |> Enum.map(&Map.get(&1, "steamid"))
    |> profiles
    {:ok, profiles}
  end

  def heroes do
    case Steam.fetch("GetHeroes", %{}, "IEconDOTA2_570") do
      {:ok, heroes} -> heroes["heroes"]
      response -> response
    end
  end

  def hero_img(id), do: Steam.get_hero_image(id)

  def items do 
    case Steam.fetch("GetGameItems", %{}, "IEconDOTA2_570") do
      {:ok, items} -> items["items"]
      response -> response
    end
  end

  def item_img(id), do: Steam.get_item_image(id)

  def steam_to_dota_id(steam_id) when is_integer(steam_id) do
    steam_id - @steam_id_diff
  end
  def steam_to_dota_id(steam_id) when is_binary(steam_id) do
    String.to_integer(steam_id) - @steam_id_diff
  end

  def dota_to_steam_id(dota_id) when is_integer(dota_id) do
    dota_id + @steam_id_diff
  end
  def dota_to_steam_id(dota_id) when is_binary(dota_id) do
    String.to_integer(dota_id) + @steam_id_diff
  end


end
