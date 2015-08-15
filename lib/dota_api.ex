defmodule DotaApi do
  alias DotaApi.Client

  ## Client API

  # Returns a single match in full detail
  def match(match_id) do
    details = Client.fetch("GetMatchDetails", %{match_id: match_id}) 
    {:ok, details}
  end

  # Returns a list of match summaries
  def history(account_id) do
    summaries = Client.fetch("GetMatchHistory", %{account_id: account_id})
    {:ok, summaries}
  end

  # This is just a proof of concept for fetching multiple
  # matches in parallel.
  def matches_for(account_id) do
    {:ok, %{"matches" => summaries}} = history(account_id)
    matches = summaries
    |> Enum.map(&async_match/1)
    |> Enum.map(&await_match/1)
    {:ok}
  end

  defp async_match(summary) do
    match_id = Map.fetch!(summary, "match_id")
    Task.async(fn -> match(match_id) end)
  end

  defp await_match(task) do
    {:ok, details} = Task.await(task)
    IO.inspect "Fetched match: #{details["match_id"]}"
    details
  end

end
