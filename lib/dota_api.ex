defmodule DotaApi do
  alias DotaApi.Client

  ## Client API

  # Returns a single match in full detail
  def match(match_id) do
    details = Client.fetch("GetMatchDetails", %{match_id: match_id}) 
    case details do
      {:error, reason} -> details
      _ -> {:ok, details}
    end
  end

  # Returns a list of match summaries
  def history(account_id) do
    summaries = Client.fetch("GetMatchHistory", %{account_id: account_id})
    case summaries do
      {:error, reason} -> summaries
      _ -> {:ok, summaries}
    end
  end

  def dotabuff_history(account_id) do
    match_ids = Client.fetch("GetDotabuffMatchHistory", account_id)
    case match_ids do
      {:error, reason} -> match_ids
      _ -> {:ok, match_ids}
    end
  end

  def match_ids_stream_dotabuff(account_id) do
    Client.match_ids_stream_dotabuff(account_id)
  end

  # This is just a proof of concept for fetching multiple
  # matches in parallel.
  def matches_for(account_id) do
    {:ok, %{"matches" => summaries}} = history(account_id)
    matches = summaries
    |> Enum.map(&Map.fetch(&1, "match_id"))
    |> Enum.map(fn {:ok, id} -> async_match(id) end)
    |> Enum.map(&await_match/1)
    {:ok, matches}
  end

  def dotabuff_matches_for(account_id) do
    {:ok, match_ids} = dotabuff_history(account_id)
    matches = p_matches(match_ids)
    {:ok, matches}
  end

  def p_matches(ids) do
    ids
    |> Enum.map(&async_match/1)
    |> Enum.map(&await_match/1)
  end

  defp async_match(id) do
    Task.async(fn -> match(id) end)
  end

  defp await_match(task) do
    {:ok, details} = Task.await(task)
    IO.inspect "Fetched match: #{details["match_id"]}"
    details
  end

  def profiles(ids) do
    profiles = Client.fetch("GetPlayerSummaries", %{steamids: Enum.join(ids, ",")},
                            "ISteamUser", "v0002")
    {:ok, profiles}
  end

  def profile(id) do
    {:ok, [profile | _]} = profiles([id])
    {:ok, profile}
  end

end
