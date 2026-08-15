defmodule AdocFormatter.Config do
  @moduledoc false

  @spec load(Path.t()) :: {:ok, keyword()} | {:error, String.t()}
  def load(path) do
    {options, _binding} = Code.eval_file(path)
    validate(options)
  rescue
    error -> {:error, "could not load #{path}: #{Exception.message(error)}"}
  end

  defp validate(options) when is_list(options) do
    cond do
      not Keyword.keyword?(options) ->
        {:error, "expected a keyword list in the formatter config"}

      Keyword.keys(options) -- [:non_breaking_phrases] != [] ->
        {:error, "formatter config contains unsupported options"}

      not valid_phrases?(Keyword.get(options, :non_breaking_phrases, [])) ->
        {:error, "non_breaking_phrases must be a list of strings"}

      true ->
        {:ok, options}
    end
  end

  defp validate(_options), do: {:error, "expected a keyword list in the formatter config"}

  defp valid_phrases?(phrases) when is_list(phrases), do: Enum.all?(phrases, &is_binary/1)
  defp valid_phrases?(_phrases), do: false
end
