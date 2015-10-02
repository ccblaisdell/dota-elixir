defmodule DotaApi.Client do
  require IEx

  def match_ids_stream_dotabuff(account_id) do
    url = dotabuff_matches_url(account_id)
    case HTTPoison.get(url, [], []) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        page_count = get_dotabuff_page_count(body)

        ids = 1..page_count
        |> Stream.map(&get_dotabuff_page(account_id, &1))
        |> Stream.map(&get_match_ids_from_page/1)

      response -> {:error, response}
    end
  end

  def fetch("GetDotabuffMatchHistory", account_id) do
    url = dotabuff_matches_url(account_id)
    case HTTPoison.get(url, [], []) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        page_count = get_dotabuff_page_count(body)

        body 
        |> get_match_ids_from_page
        |> DotaApi.p_matches

        match_stream = 2..page_count
        |> Stream.map(&get_dotabuff_page(account_id, &1))
        |> Stream.map(&get_match_ids_from_page/1)
        |> Stream.map(&DotaApi.async_matches/1)

        Enum.to_list(match_stream)

      response -> {:error, response}
    end
  end

  def get_dotabuff_page(account_id, page) do
    url = dotabuff_matches_url(account_id, page)
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body
      response -> 
        {:error, response}
    end
  end

  defp dotabuff_matches_url(account_id) do
    "http://www.dotabuff.com/players/#{account_id}/matches"
  end

  defp dotabuff_matches_url(account_id, page) do
    "http://www.dotabuff.com/players/#{account_id}/matches?page=#{page}"
  end

  def fetch("GetPlayerSummaries" = method, options, interface, api_version) do
    url = build_url(method, options, interface, api_version)
    params = get_params(options)
    case HTTPoison.get(url, [], params) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        response = Poison.Parser.parse!(body)
        response["response"]["players"]
      response -> response
    end
  end

  def fetch(method, options \\ %{}, interface \\ "IDOTA2Match_570", api_version \\ "V001") do
    url = build_url(method, options, interface, api_version)
    params = get_params(options)
    case HTTPoison.get(url, [], params) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        response = Poison.Parser.parse!(body)
        response["result"]
      response -> response
    end
  end

  defp build_url(method, options, interface, api_version) do
    "https://api.steampowered.com/#{interface}/#{method}/#{api_version}"
  end

  defp get_params(options) do
    api_key = System.get_env("STEAM_WEB_API_KEY")
    params = options
    |> Map.put(:key, api_key)
    |> Enum.into([])
    [params: params]
  end

  defp get_dotabuff_page_count(body) do
    {_tag, _attrs, [viewport]} = Floki.find(body, ".viewport") |> hd
    match_count = viewport |> String.split(" of ") |> tl |> hd |> String.to_integer
    match_count / 50 |> Float.ceil |> round
  end

  defp get_match_ids_from_page(body) do
    body 
    |> Floki.find(".cell-large a") 
    |> Floki.attribute("href") 
    |> Enum.map(&String.split(&1, "/"))
    |> Enum.map(&List.last/1)
    |> Enum.map(&String.to_integer/1)
  end
end
