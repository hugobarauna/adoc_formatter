defmodule AdocFormatter do
  @moduledoc """
  Formats AsciiDoc source without changing its rendered content.
  """

  @doc """
  Formats `source` using one sentence per line.
  """
  def format(source, options \\ []) when is_binary(source) and is_list(options) do
    source
    |> AdocFormatter.Scanner.scan()
    |> Enum.map_join(fn
      {:raw, text} ->
        text

      {:prose, text, metadata} ->
        if Regex.match?(~r/ \+(?:\r\n|\n|\r)/, text) do
          text
        else
          format_paragraph(text, metadata, options)
        end
    end)
  end

  defp format_paragraph(source, metadata, options) do
    {body, trailing_newline, line_ending} = split_trailing_newline(source)

    normalized =
      body
      |> String.replace_prefix(metadata.prefix, "")
      |> String.replace(~r/[ \t]*(?:\r\n|\n|\r)[ \t]*/, " ")

    formatted =
      normalized
      |> sentence_segments(options)
      |> Enum.map_join(line_ending <> metadata.continuation_prefix, &String.trim_trailing/1)

    metadata.prefix <> formatted <> trailing_newline
  end

  defp sentence_segments(source, options) do
    shadow = AdocFormatter.InlineShadow.project(source, options)

    {segments, _offset} =
      shadow
      |> Unicode.String.split(break: :sentence, locale: :root)
      |> Enum.map_reduce(0, fn segment, offset ->
        size = byte_size(segment)
        {binary_part(source, offset, size), offset + size}
      end)

    merge_unspaced_boundaries(segments)
  end

  # A line break renders as a plain space, so a split is only safe where the
  # source already had one; glue segments back together everywhere else.
  defp merge_unspaced_boundaries(segments) do
    segments
    |> Enum.reduce([], fn
      segment, [] ->
        [segment]

      segment, [previous | rest] ->
        if String.ends_with?(previous, [" ", "\t"]) do
          [segment, previous | rest]
        else
          [previous <> segment | rest]
        end
    end)
    |> Enum.reverse()
  end

  defp split_trailing_newline(source) do
    case Regex.run(~r/(\r\n|\n|\r)\z/, source, capture: :all_but_first) do
      [line_ending] ->
        body_size = byte_size(source) - byte_size(line_ending)
        {binary_part(source, 0, body_size), line_ending, line_ending}

      nil ->
        line_ending =
          case Regex.run(~r/\r\n|\n|\r/, source) do
            [existing] -> existing
            nil -> "\n"
          end

        {source, "", line_ending}
    end
  end
end
