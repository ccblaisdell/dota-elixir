defmodule Dota.Dotabuff do
  require IEx

  def match_ids_stream(account_id) do
    url = matches_url(account_id)
    case HTTPoison.get(url, [], []) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        page_count = get_page_count(body)

        1..page_count
        |> Stream.map(&get_page(account_id, &1))
        |> Stream.map(&get_match_ids_from_page/1)

      response -> {:error, response}
    end
  end

  defp get_page(account_id, page) do
    url = matches_url(account_id, page)
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body
      response -> 
        {:error, response}
    end
  end

  defp matches_url(account_id) do
    "http://www.dotabuff.com/players/#{account_id}/matches"
  end

  defp matches_url(account_id, page) do
    "http://www.dotabuff.com/players/#{account_id}/matches?page=#{page}"
  end

  defp get_page_count(body) do
    {_tag, _attrs, [viewport]} = Floki.find(body, ".viewport") |> hd
    match_count = viewport |> String.split(" of ") |> tl |> hd |> String.to_integer
    match_count / 50 |> Float.ceil |> round
  end

  # Returns a list of match IDs as strings
  defp get_match_ids_from_page(body) do
    body 
    |> Floki.find(".cell-large a") 
    |> Floki.attribute("href") 
    |> Enum.map(&String.split(&1, "/"))
    |> Enum.map(&List.last/1)
  end
end
