defmodule Exsolr.Searcher do
  @moduledoc """
  Provides search functions to Solr
  """

  require Logger

  alias Exsolr.Config
  alias Exsolr.HttpResponse

  @doc """
  Receives the query params, converts them to an url, queries Solr and builds
  the response
  """
  def get(params, options) do
    collection = options[:collection]
    params
    |> build_solr_query
    |> do_search(collection)
    |> extract_response
  end

  @doc """
  Builds the solr url query. It will use the following default values if they
  are not specifier

  wt: "json"
  q: "*:*"
  start: 0
  rows: 10

  ## Examples

      iex> Exsolr.Searcher.build_solr_query(q: "roses", fq: ["blue", "violet"])
      "?wt=json&start=0&rows=10&q=roses&fq=blue&fq=violet"

      iex> Exsolr.Searcher.build_solr_query(q: "roses", fq: ["blue", "violet"], start: 0, rows: 10)
      "?wt=json&q=roses&fq=blue&fq=violet&start=0&rows=10"

      iex> Exsolr.Searcher.build_solr_query(q: "roses", fq: ["blue", "violet"], wt: "xml")
      "?start=0&rows=10&q=roses&fq=blue&fq=violet&wt=xml"

  """
  def build_solr_query(params) do
    "?" <> build_solr_query_params(params)
  end

  defp build_solr_query_params(params) do
    params
    |> add_default_params
    |> Enum.map(fn({key, value}) -> build_solr_query_parameter(key, value) end)
    |> Enum.join("&")
  end

  defp add_default_params(params) do
    default_parameters
    |> Keyword.merge(params)
  end

  defp default_parameters do
    [wt: "json", q: "*:*", start: 0, rows: 10]
  end

  defp build_solr_query_parameter(_, []), do: nil
  defp build_solr_query_parameter(key, [head|tail]) do
    [build_solr_query_parameter(key, head), build_solr_query_parameter(key, tail)]
    |> Enum.reject(fn(x) -> x == nil end)
    |> Enum.join("&")
  end
  defp build_solr_query_parameter(:q, value) do
    "q=#{encode_value(value)}"
  end
  defp build_solr_query_parameter(key, value) do
    [Atom.to_string(key), encode_value(value)]
    |> Enum.join("=")
  end

  def do_search(solr_query, collection) do
    solr_query
    |> build_solr_url(collection)
    |> HTTPoison.get
    |> HttpResponse.body
  end

  defp build_solr_url(solr_query, collection) do
    url = Config.select_url(collection) <> solr_query
    _ = Logger.debug url
    url
  end

  defp extract_response(solr_response) do
    case solr_response |> Poison.decode do
      {:ok, %{"response" => response, "moreLikeThis" => moreLikeThis}} -> Map.put(response, "mlt", extract_mlt_result(moreLikeThis))
      {:ok, %{"response" => response}} -> response
    end
  end

  defp encode_value(value) when is_binary(value) do
    URI.encode_www_form(value)
  end

  defp encode_value(value) do
    value
  end

  defp extract_mlt_result(mlt) do
    result =
    for k <- Map.keys(mlt), do: get_in(mlt, [k, "docs"])
    result |> List.flatten
  end
end
