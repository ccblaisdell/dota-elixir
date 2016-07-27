defmodule Dota.Steam do
  require IEx
  require Logger

  @hero_img_sizes ~w(sb.png lg.png full.png)

  def fetch("GetDotabuffMatchHistory", account_id), do: Dota.Dotabuff.history(account_id)
  
  def fetch("GetPlayerSummaries" = method, options, interface, api_version) do
    case do_fetch(method, options, interface, api_version) do
      {:ok, response} -> {:ok, response["players"]}
      response -> response
    end
  end
  
  def fetch("GetFriendList" = method, options, "ISteamUser" = interface, api_version) do
    case do_fetch(method, options, interface, api_version) do
      {:ok, result} -> {:ok, result["friends"]}
      response -> response
    end
  end
  
  def fetch("GetMatchHistoryIds" = method, options, interface, api_version) do
    case fetch("GetMatchHistory", options, interface, api_version) do
      {:ok, %{"matches" => summaries}} ->
        ids = summaries
        |> Enum.map(&Map.fetch(&1, "match_id"))
        |> Enum.map(fn {:ok, match_id} -> match_id end)
        |> Enum.map(&to_string/1)
        {:ok, ids}
    end
  end
  
  def fetch("GetMatchHistory" = method, options, interface, api_version) do
    case do_fetch(method, options, interface, api_version) do
      {:ok, result} ->
        Map.update!(result, "matches", fn matches ->
          Enum.map(matches, fn m -> Map.update!(m, "match_id", &to_string/1) end)
        end)
        {:ok, result}
      response -> 
        response
    end
  end

  def fetch(method, options \\ %{}, interface \\ "IDOTA2Match_570", api_version \\ "v0001") do
    do_fetch(method, options, interface, api_version)
  end
  
  defp do_fetch("GetPlayerSummaries" = method, options, interface, api_version) do
    url = build_url(method, interface, api_version)
    params = get_params(options)
    case HTTPoison.get(url, [], params) do
      
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        response = Poison.Parser.parse!(body)
        case response["response"] do
          %{"error" => reason} -> 
            Logger.error(reason)
            {:error, reason}
          %{"status" => 15, "statusDetail" => details} -> 
            Logger.error(details)
            {:error, details}
          _ -> 
            {:ok, response["response"]}
        end
        
      {:ok, %HTTPoison.Response{status_code: 503, body: body}} ->
        {:error, "Service unavailable"}
        
      response -> 
        {:error, response}
        
    end
  end
    
  defp do_fetch(method, options \\ %{}, interface \\ "IDOTA2Match_570", api_version \\ "v0001") do
    url = build_url(method, interface, api_version)
    params = get_params(options)
    case HTTPoison.get(url, [], params) do
      
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        response = Poison.Parser.parse!(body)
        case response["result"] do
          %{"error" => reason} -> 
            Logger.error(reason)
            {:error, reason}
          %{"status" => 15, "statusDetail" => details} -> 
            Logger.error(details)
            {:error, details}
          _ -> 
            {:ok, response["result"]}
        end
        
      {:ok, %HTTPoison.Response{status_code: 503, body: body}} ->
        {:error, "Service unavailable"}
        
      response -> 
        Logger.error(response)
        {:error, response}
      
    end
  end

  defp build_url(method, interface, api_version) do
    "https://api.steampowered.com/#{interface}/#{method}/#{api_version}"
  end

  defp get_params(options) do
    api_key = System.get_env("STEAM_WEB_API_KEY")
    params = options
    |> Map.put(:key, api_key)
    |> Map.put(:language, "en_us")
    |> Enum.into([])
    [params: params]
  end

  def get_item_image(id) do
    name = Dota.Item.name(id)
    url = "http://cdn.dota2.com/apps/dota2/images/items/#{name}_lg.png"
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        Logger.debug "Downloaded image for #{name}"
        {:ok, body}
      response -> 
        Logger.error "Failed to download image for #{name}"
        response
    end
  end

  def get_hero_image(id) do
    name = Dota.Hero.name(id)
    base_url = "http://cdn.dota2.com/apps/dota2/images/heroes/#{name}_"
    @hero_img_sizes |> Enum.map(&get_hero_image(&1, base_url))
  end

  defp get_hero_image(size, base_url) do
    url = base_url <> size
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body, size}
      response -> response
    end
  end
end
