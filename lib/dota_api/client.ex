defmodule DotaApi.Client do
  require IEx

  def fetch("GetPlayerSummaries" = method, options, interface, api_version) do
    url = build_url(method, options, interface, api_version)
    case HTTPoison.get(url, [], []) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        response = Poison.Parser.parse!(body)
        response["response"]["players"]
      response -> response
    end
  end

  def fetch(method, options \\ %{}, interface \\ "IDOTA2Match_570", api_version \\ "V001") do
    url = build_url(method, options, interface, api_version)
    case HTTPoison.get(url, [], []) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        response = Poison.Parser.parse!(body)
        response["result"]
      response -> response
    end
  end

  defp build_url(method, options, interface, api_version) do
    base_url = "https://api.steampowered.com/#{interface}/#{method}/#{api_version}?"
    add_params(base_url, options)
  end

  defp add_params(url, params) do
    api_key = System.get_env("STEAM_WEB_API_KEY")
    params = Map.put(params, :key, api_key)
    encoded_params = params
    |> Map.keys()
    |> Enum.map(fn k -> "#{k}=#{Map.fetch!(params, k)}" end)
    |> Enum.join("&")
    url <> encoded_params
  end
end
