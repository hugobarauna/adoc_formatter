defmodule AdocFormatter.Scanner do
  @moduledoc false

  @type segment ::
          {:raw, String.t()}
          | {:prose, String.t(), %{prefix: String.t(), continuation_prefix: String.t()}}

  @spec scan(String.t()) :: [segment()]
  def scan(source) when is_binary(source) do
    source
    |> lines()
    |> Enum.reduce({[], nil, nil, nil}, &scan_line/2)
    |> flush_paragraph()
    |> elem(0)
    |> Enum.reverse()
  end

  defp scan_line(line, {segments, paragraph, block, pending_style}) do
    body = line_body(line)

    cond do
      match?({:opaque, _delimiter}, block) ->
        {:opaque, delimiter} = block
        next_block = if body == delimiter, do: nil, else: block
        {segments, nil, _, _} = flush_paragraph({segments, paragraph, block, nil})
        {[{:raw, line} | segments], nil, next_block, nil}

      match?({:prose, ^body}, block) ->
        {segments, nil, _, _} = flush_paragraph({segments, paragraph, block, nil})
        {[{:raw, line} | segments], nil, nil, nil}

      opaque_delimiter?(body) ->
        {segments, nil, _, _} = flush_paragraph({segments, paragraph, block, nil})
        {[{:raw, line} | segments], nil, {:opaque, body}, nil}

      body in ["====", "****", "____"] ->
        {segments, nil, _, _} = flush_paragraph({segments, paragraph, block, nil})
        mode = if pending_style == :opaque, do: :opaque, else: :prose
        {[{:raw, line} | segments], nil, {mode, body}, nil}

      indented_literal?(body, paragraph) ->
        {segments, nil, _, _} = flush_paragraph({segments, paragraph, block, nil})
        {[{:raw, line} | segments], nil, block, nil}

      raw_line?(body) ->
        {segments, nil, _, _} = flush_paragraph({segments, paragraph, block, nil})
        {[{:raw, line} | segments], nil, block, pending_style(body, pending_style)}

      list_metadata = list_prefix(body) ->
        {segments, nil, block, _} = flush_paragraph({segments, paragraph, block, nil})
        {prefix, continuation_prefix} = list_metadata

        paragraph = %{
          continuation_prefix: continuation_prefix,
          lines: [line],
          prefix: prefix
        }

        {segments, paragraph, block, nil}

      true ->
        paragraph = paragraph || %{continuation_prefix: "", lines: [], prefix: ""}
        {segments, %{paragraph | lines: [line | paragraph.lines]}, block, nil}
    end
  end

  defp flush_paragraph({segments, nil, block, pending_style}),
    do: {segments, nil, block, pending_style}

  defp flush_paragraph({segments, paragraph, block, pending_style}) do
    text = paragraph.lines |> Enum.reverse() |> Enum.join()

    metadata = %{
      continuation_prefix: paragraph.continuation_prefix,
      prefix: paragraph.prefix
    }

    {[{:prose, text, metadata} | segments], nil, block, pending_style}
  end

  defp raw_line?(body) do
    String.trim(body) == "" or
      String.starts_with?(body, "//") or
      String.starts_with?(body, "> ") or
      body in ["<<<", "+", "'''"] or
      Regex.match?(~r/^=+\s+/, body) or
      Regex.match?(~r/^:[^:]+:/, body) or
      Regex.match?(~r/^\[.*\]$/, body) or
      Regex.match?(~r/^\.[^\s.]/, body) or
      Regex.match?(~r/^(?:include|ifdef|ifndef|ifeval|endif|image|video|audio|toc)::/, body)
  end

  defp opaque_delimiter?(body) do
    body in ["....", "++++", "////", "|==="] or Regex.match?(~r/^-{4,}$/, body)
  end

  defp line_body(line), do: Regex.replace(~r/(?:\r\n|\n|\r)\z/, line, "")

  defp list_prefix(body) do
    case Regex.run(~r/^(?:\*+|-|\.+|\d+\.|<\d+>)[ \t]+/, body) do
      [prefix] ->
        {prefix, String.duplicate(" ", String.length(prefix))}

      nil ->
        case Regex.run(~r/^.+?::[ \t]+/, body) do
          [prefix] -> {prefix, ""}
          nil -> nil
        end
    end
  end

  defp pending_style(body, current_style) do
    cond do
      Regex.match?(~r/^\[verse(?:,|\])/, body) -> :opaque
      Regex.match?(~r/^\[/, body) -> nil
      String.starts_with?(body, ".") -> current_style
      true -> nil
    end
  end

  defp indented_literal?(body, paragraph) do
    indented? = String.starts_with?(body, [" ", "\t"])

    list_continuation? =
      paragraph != nil and paragraph.prefix != "" and
        String.starts_with?(body, paragraph.continuation_prefix)

    indented? and not list_continuation?
  end

  defp lines(source) do
    ~r/[^\r\n]*(?:\r\n|\n|\r|$)/
    |> Regex.scan(source)
    |> List.flatten()
    |> Enum.reject(&(&1 == ""))
  end
end
