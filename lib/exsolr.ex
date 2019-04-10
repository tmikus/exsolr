defmodule Exsolr do
  @moduledoc """
  Solr wrapper made in Elixir.
  """

  alias Exsolr.Config
  alias Exsolr.Indexer
  alias Exsolr.Searcher

  @doc """
  Returns a map containing the solr connection info

  ## Examples

      iex> Exsolr.info
      %{hostname: "localhost", port: 8983, core: "elixir_test"}
  """
  def info do
    Config.info
  end

  @doc """
  Send a search request to Solr.

  ## Example

      iex> Exsolr.get(q: "roses", fq: ["blue", "violet"])
      iex> Exsolr.get(q: "red roses", defType: "disMax")

  """
  def get(query_params, options \\ %{}) do
    Searcher.get(query_params, options)
  end

  @doc """
  Adds the `document` to Solr.

  ## Example

      iex> Exsolr.add(%{id: 1, price: 1.00})

  """
  def add(document, options \\ %{}) do
    Indexer.add(document, options)
  end

  @doc """
  Commits the pending changes to Solr
  """
  def commit(options \\ %{}) do
    Indexer.commit(options)
  end

  @doc """
  Delete the document with id `id` from the solr index
  """
  def delete_by_id(id, options \\ %{}) do
    Indexer.delete_by_id(id, options)
  end

  @doc """
  Delete all the documents from the Solr index

  https://wiki.apache.org/solr/FAQ#How_can_I_delete_all_documents_from_my_index.3F
  """
  def delete_all(options \\ %{}) do
    Indexer.delete_all(options)
  end
end
