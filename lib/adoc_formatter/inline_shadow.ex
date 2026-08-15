defmodule AdocFormatter.InlineShadow do
  @moduledoc false

  @spec project(String.t(), keyword()) :: String.t()
  def project(source, options \\ []) when is_binary(source) and is_list(options) do
    source
    |> mask_non_breaking_boundaries()
    |> mask_opening_ellipses()
    |> mask_connected_ellipses()
    |> mask_initials()
    |> mask_non_breaking_phrases(Keyword.get(options, :non_breaking_phrases, []))
    |> mask_monospace()
    |> mask_attached_footnotes()
    |> mask_inline_macros()
    |> suppress_mid_sentence_terminal()
    |> normalize_inline_closers()
  end

  defp mask_non_breaking_boundaries(source) do
    Regex.replace(~r/[.!?]+\x{00A0}+/u, source, &mask/1)
  end

  defp mask_connected_ellipses(source) do
    Regex.replace(~r/\.{3}(?=\p{L})/u, source, &mask/1)
  end

  defp mask_opening_ellipses(source) do
    Regex.replace(~r/(["“])(\.{3})(?=\s+\p{L})/u, source, fn _match, quote, ellipsis ->
      quote <> mask(ellipsis)
    end)
  end

  defp mask_initials(source) do
    Regex.replace(
      ~r/\b\p{Lu}\.(?=(?:\s+\p{Lu}(?:\.|\p{Ll})|[,;]|\s*\())/u,
      source,
      &String.replace_suffix(&1, ".", "x")
    )
  end

  defp mask_non_breaking_phrases(source, phrases) do
    Enum.reduce(phrases, source, fn phrase, shadow ->
      pattern =
        Regex.compile!(
          "(?<![\\p{L}\\p{N}_])#{Regex.escape(phrase)}(?![\\p{L}\\p{N}_])",
          "u"
        )

      Regex.replace(pattern, shadow, &mask/1)
    end)
  end

  defp mask_monospace(source) do
    Regex.replace(~r/``[^\r\n]*?``|`[^`\r\n]*`/u, source, &mask/1)
  end

  defp mask_attached_footnotes(source) do
    Regex.replace(
      ~r/([.!?])((?:\s*\{empty\})?)(footnote:\[[^\]\r\n]*\])(?=\s|$)/u,
      source,
      fn _match, terminal, attachment, footnote ->
        mask(terminal) <> mask(attachment) <> mask_with_terminal(footnote, terminal)
      end
    )
  end

  defp mask_inline_macros(source) do
    Regex.replace(
      ~r/\b[A-Za-z][A-Za-z0-9_-]*:[^\s\[]*\[[^\]\r\n]*\]/u,
      source,
      &mask/1
    )
  end

  defp normalize_inline_closers(source) do
    Regex.replace(
      ~r/([.!?](?:["'”’»]+)?)([*_#^~]+)(?=\s|$)/u,
      source,
      fn _match, terminal_and_quotes, closers ->
        terminal_and_quotes <> String.duplicate(")", byte_size(closers))
      end
    )
  end

  defp suppress_mid_sentence_terminal(source) do
    Regex.replace(
      ~r/([!?])(["'”’»]*)([)*_#^~]*)(\s+)(?=\p{Ll})/u,
      source,
      fn _match, _terminal, quotes, closers, whitespace ->
        "x" <> quotes <> String.duplicate(")", byte_size(closers)) <> whitespace
      end
    )
  end

  defp mask(text), do: String.duplicate("x", byte_size(text))

  defp mask_with_terminal(text, terminal) do
    String.duplicate("x", byte_size(text) - byte_size(terminal)) <> terminal
  end
end
