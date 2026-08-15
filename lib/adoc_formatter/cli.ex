defmodule AdocFormatter.CLI do
  @moduledoc false

  @usage """
  Usage: adoc_formatter [--write | --check] [--config PATH] PATH...

    --write        Format files in place
    --check        Report files that would change
    --config PATH  Load formatter options from PATH
    --help         Show this help

  PATH may be a file, directory, glob, or - for stdin.
  """

  @spec main([String.t()]) :: :ok
  def main(arguments) do
    case run(arguments) do
      0 -> :ok
      status -> System.halt(status)
    end
  end

  @spec run([String.t()], keyword()) :: non_neg_integer()
  def run(arguments, io_options \\ []) do
    stdin = Keyword.get(io_options, :stdin, :stdio)
    stdout = Keyword.get(io_options, :stdout, :stdio)
    stderr = Keyword.get(io_options, :stderr, :stderr)

    case OptionParser.parse(arguments,
           strict: [write: :boolean, check: :boolean, config: :string, help: :boolean]
         ) do
      {options, paths, []} ->
        cond do
          options[:help] == true ->
            IO.write(stdout, @usage)
            0

          paths == [] ->
            usage_error(stderr, [])

          options[:write] == true and options[:check] == true ->
            IO.puts(stderr, "--write and --check cannot be used together")
            2

          true ->
            case load_config(options[:config]) do
              {:ok, formatter_options} ->
                run_paths(
                  resolve_paths(paths),
                  options,
                  formatter_options,
                  stdin,
                  stdout,
                  stderr
                )

              {:error, message} ->
                IO.puts(stderr, message)
                2
            end
        end

      {_options, _paths, invalid} ->
        usage_error(stderr, invalid)
    end
  end

  defp run_paths(paths, options, formatter_options, stdin, stdout, stderr) do
    cond do
      paths == [] ->
        usage_error(stderr, [])

      options[:write] == true and "-" in paths ->
        IO.puts(stderr, "cannot use --write with stdin")
        2

      options[:write] != true and options[:check] != true and length(paths) != 1 ->
        IO.puts(stderr, "stdout mode expects exactly one input file")
        2

      true ->
        paths
        |> Enum.map(&run_file(&1, options, formatter_options, stdin, stdout, stderr))
        |> Enum.max()
    end
  end

  defp run_file(path, options, formatter_options, stdin, stdout, stderr) do
    case read_source(path, stdin) do
      {:ok, source} ->
        formatted = AdocFormatter.format(source, formatter_options)

        if options[:check] do
          if source == formatted do
            0
          else
            IO.puts(stdout, path)
            1
          end
        else
          write_or_print(path, formatted, options, stdout, stderr)
        end

      {:error, reason} ->
        file_error(stderr, "read", path, reason)
    end
  end

  defp write_or_print(path, formatted, options, stdout, stderr) do
    if options[:write] do
      case File.write(path, formatted) do
        :ok -> 0
        {:error, reason} -> file_error(stderr, "write", path, reason)
      end
    else
      IO.write(stdout, formatted)
      0
    end
  end

  defp usage_error(stderr, invalid) do
    detail = if invalid == [], do: "expected exactly one input path", else: "invalid options"
    IO.write(stderr, "#{detail}\n#{@usage}")
    2
  end

  defp file_error(stderr, operation, path, reason) do
    IO.puts(stderr, "could not #{operation} #{path}: #{:file.format_error(reason)}")
    2
  end

  defp read_source("-", stdin) do
    case IO.read(stdin, :eof) do
      :eof -> {:ok, ""}
      {:error, reason} -> {:error, reason}
      data when is_binary(data) -> {:ok, data}
    end
  end

  defp read_source(path, _stdin), do: File.read(path)

  defp resolve_paths(paths) do
    paths
    |> Enum.flat_map(&resolve_path/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp resolve_path(path) do
    cond do
      File.dir?(path) -> Path.wildcard(Path.join(path, "**/*.adoc"))
      String.contains?(path, ["*", "?", "["]) -> Path.wildcard(path)
      true -> [path]
    end
  end

  defp load_config(nil) do
    if File.regular?(".adoc_formatter.exs") do
      AdocFormatter.Config.load(".adoc_formatter.exs")
    else
      {:ok, []}
    end
  end

  defp load_config(path), do: AdocFormatter.Config.load(path)
end
