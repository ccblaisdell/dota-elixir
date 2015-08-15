defmodule DotaApi.Client do
  def fetch(method, options \\ %{}) do
    base_url = "https://api.steampowered.com/" <> "IDOTA2Match_570/#{method}/V001?"
    url = add_params(base_url, options)

    case HTTPoison.get(url, [], []) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        response = Poison.Parser.parse!(body)
        response["result"]
      response -> response
    end
  end

  defp add_params(url, params) do
    api_key = Dict.fetch!(Application.get_env(:steam, :web_api), :key)
    params = Map.put(params, :key, api_key)
    encoded_params = params
    |> Map.keys()
    |> Enum.map(fn k -> "#{k}=#{Map.fetch!(params, k)}" end)
    |> Enum.join("&")
    url <> encoded_params
  end
end
