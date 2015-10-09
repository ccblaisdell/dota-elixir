defmodule Dota.Steam do
  require IEx

  @hero_img_sizes ~w(sb.png lg.png full.png)

  def fetch("GetDotabuffMatchHistory", account_id), do: Dota.Dotabuff.history(account_id)

  def fetch("GetPlayerSummaries" = method, options, interface, api_version) do
    url = build_url(method, interface, api_version)
    params = get_params(options)
    case HTTPoison.get(url, [], params) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        response = Poison.Parser.parse!(body)
        response["response"]["players"]
      response -> response
    end
  end

  def fetch(method, options \\ %{}, interface \\ "IDOTA2Match_570", api_version \\ "V001") do
    url = build_url(method, interface, api_version)
    params = get_params(options)
    case HTTPoison.get(url, [], params) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        response = Poison.Parser.parse!(body)
        response["result"]
      response -> response
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
        {:ok, body}
      response -> response
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
