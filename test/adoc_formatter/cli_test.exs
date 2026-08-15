defmodule AdocFormatter.CLITest do
  use ExUnit.Case

  alias AdocFormatter.CLI

  describe "run/2" do
    @describetag :tmp_dir

    test "prints a formatted file to stdout by default", %{tmp_dir: directory} do
      path = Path.join(directory, "chapter.adoc")
      File.write!(path, "First sentence. Second sentence.\n")
      {:ok, stdout} = StringIO.open("")
      {:ok, stderr} = StringIO.open("")

      assert CLI.run([path], stdout: stdout, stderr: stderr) == 0
      assert {_input, "First sentence.\nSecond sentence.\n"} = StringIO.contents(stdout)
      assert {_input, ""} = StringIO.contents(stderr)
    end

    test "writes formatted content back to a file with --write", %{tmp_dir: directory} do
      path = Path.join(directory, "chapter.adoc")
      File.write!(path, "First sentence. Second sentence.\n")
      {:ok, stdout} = StringIO.open("")
      {:ok, stderr} = StringIO.open("")

      assert CLI.run(["--write", path], stdout: stdout, stderr: stderr) == 0
      assert File.read!(path) == "First sentence.\nSecond sentence.\n"
      assert {_input, ""} = StringIO.contents(stderr)
    end

    test "writes every AsciiDoc file under a directory", %{tmp_dir: directory} do
      first_path = Path.join(directory, "first.adoc")
      second_path = Path.join(directory, "nested/second.adoc")
      ignored_path = Path.join(directory, "notes.md")
      File.mkdir_p!(Path.dirname(second_path))
      File.write!(first_path, "First sentence. Second sentence.\n")
      File.write!(second_path, "Third sentence. Fourth sentence.\n")
      File.write!(ignored_path, "Leave this. Untouched.\n")
      {:ok, stderr} = StringIO.open("")

      assert CLI.run(["--write", directory], stderr: stderr) == 0
      assert File.read!(first_path) == "First sentence.\nSecond sentence.\n"
      assert File.read!(second_path) == "Third sentence.\nFourth sentence.\n"
      assert File.read!(ignored_path) == "Leave this. Untouched.\n"
      assert {_input, ""} = StringIO.contents(stderr)
    end

    test "reports a directory containing no AsciiDoc files", %{tmp_dir: directory} do
      File.write!(Path.join(directory, "notes.md"), "Not AsciiDoc. Leave alone.\n")
      {:ok, stdout} = StringIO.open("")
      {:ok, stderr} = StringIO.open("")

      assert CLI.run(["--check", directory], stdout: stdout, stderr: stderr) == 2
      assert {_input, ""} = StringIO.contents(stdout)
      assert {_input, output} = StringIO.contents(stderr)
      assert output == "no .adoc files found matching #{directory}\n"
    end

    test "reports a glob matching nothing without processing the other paths", %{
      tmp_dir: directory
    } do
      path = Path.join(directory, "chapter.adoc")
      source = "First sentence. Second sentence.\n"
      File.write!(path, source)
      {:ok, stderr} = StringIO.open("")

      glob = Path.join(directory, "typo-*.adoc")
      assert CLI.run(["--write", path, glob], stderr: stderr) == 2
      assert File.read!(path) == source
      assert {_input, output} = StringIO.contents(stderr)
      assert output == "no .adoc files found matching #{glob}\n"
    end

    test "reports an unformatted file without changing it with --check", %{tmp_dir: directory} do
      path = Path.join(directory, "chapter.adoc")
      source = "First sentence. Second sentence.\n"
      File.write!(path, source)
      {:ok, stdout} = StringIO.open("")
      {:ok, stderr} = StringIO.open("")

      assert CLI.run(["--check", path], stdout: stdout, stderr: stderr) == 1
      assert File.read!(path) == source
      assert {_input, output} = StringIO.contents(stdout)
      assert output == "#{path}\n"
      assert {_input, ""} = StringIO.contents(stderr)
    end

    test "lists only the unformatted files and exits 1 with --check", %{tmp_dir: directory} do
      formatted_path = Path.join(directory, "formatted.adoc")
      unformatted_path = Path.join(directory, "unformatted.adoc")
      File.write!(formatted_path, "One sentence only.\n")
      File.write!(unformatted_path, "First sentence. Second sentence.\n")
      {:ok, stdout} = StringIO.open("")
      {:ok, stderr} = StringIO.open("")

      status =
        CLI.run(["--check", formatted_path, unformatted_path], stdout: stdout, stderr: stderr)

      assert status == 1
      assert {_input, output} = StringIO.contents(stdout)
      assert output == "#{unformatted_path}\n"
      assert {_input, ""} = StringIO.contents(stderr)
    end

    test "reports an unreadable file", %{tmp_dir: directory} do
      path = Path.join(directory, "missing.adoc")
      {:ok, stdout} = StringIO.open("")
      {:ok, stderr} = StringIO.open("")

      assert CLI.run([path], stdout: stdout, stderr: stderr) == 2
      assert {_input, output} = StringIO.contents(stderr)
      assert output == "could not read #{path}: no such file or directory\n"
    end

    test "rejects an invocation without paths" do
      {:ok, stderr} = StringIO.open("")

      assert CLI.run([], stderr: stderr) == 2
      assert {_input, output} = StringIO.contents(stderr)
      assert output =~ "Usage: adoc_formatter"
    end

    test "rejects an unknown option", %{tmp_dir: directory} do
      path = Path.join(directory, "chapter.adoc")
      File.write!(path, "First sentence. Second sentence.\n")
      {:ok, stderr} = StringIO.open("")

      assert CLI.run(["--bogus", path], stderr: stderr) == 2
      assert {_input, output} = StringIO.contents(stderr)
      assert output =~ "invalid options"
    end

    test "rejects stdout mode with more than one file", %{tmp_dir: directory} do
      first_path = Path.join(directory, "first.adoc")
      second_path = Path.join(directory, "second.adoc")
      File.write!(first_path, "First sentence. Second sentence.\n")
      File.write!(second_path, "Third sentence. Fourth sentence.\n")
      {:ok, stderr} = StringIO.open("")

      assert CLI.run([first_path, second_path], stderr: stderr) == 2
      assert {_input, output} = StringIO.contents(stderr)
      assert output =~ "stdout mode expects exactly one input file"
    end

    test "rejects using --write and --check together", %{tmp_dir: directory} do
      path = Path.join(directory, "chapter.adoc")
      File.write!(path, "First sentence. Second sentence.\n")
      {:ok, stderr} = StringIO.open("")

      assert CLI.run(["--write", "--check", path], stderr: stderr) == 2
      assert {_input, output} = StringIO.contents(stderr)
      assert output =~ "cannot be used together"
    end

    test "loads non-breaking phrases from --config", %{tmp_dir: directory} do
      path = Path.join(directory, "chapter.adoc")
      config_path = Path.join(directory, ".adoc_formatter.exs")
      File.write!(path, "Yahoo! Finance provides data. Next sentence.\n")
      File.write!(config_path, ~S([non_breaking_phrases: ["Yahoo! Finance"]]))
      {:ok, stdout} = StringIO.open("")
      {:ok, stderr} = StringIO.open("")

      assert CLI.run(["--config", config_path, path], stdout: stdout, stderr: stderr) == 0

      assert {_input, "Yahoo! Finance provides data.\nNext sentence.\n"} =
               StringIO.contents(stdout)

      assert {_input, ""} = StringIO.contents(stderr)
    end

    test "loads .adoc_formatter.exs from the working directory", %{tmp_dir: directory} do
      File.write!(Path.join(directory, "chapter.adoc"), "Yahoo! Finance provides data. Next.\n")

      File.write!(
        Path.join(directory, ".adoc_formatter.exs"),
        ~S([non_breaking_phrases: ["Yahoo! Finance"]])
      )

      {:ok, stdout} = StringIO.open("")
      {:ok, stderr} = StringIO.open("")

      status =
        File.cd!(directory, fn ->
          CLI.run(["chapter.adoc"], stdout: stdout, stderr: stderr)
        end)

      assert status == 0
      assert {_input, "Yahoo! Finance provides data.\nNext.\n"} = StringIO.contents(stdout)
      assert {_input, ""} = StringIO.contents(stderr)
    end

    test "formats stdin when the input path is a dash" do
      {:ok, stdin} = StringIO.open("First sentence. Second sentence.\n")
      {:ok, stdout} = StringIO.open("")
      {:ok, stderr} = StringIO.open("")

      assert CLI.run(["-"], stdin: stdin, stdout: stdout, stderr: stderr) == 0
      assert {_input, "First sentence.\nSecond sentence.\n"} = StringIO.contents(stdout)
      assert {_input, ""} = StringIO.contents(stderr)
    end

    test "formats empty stdin as empty output" do
      {:ok, stdin} = StringIO.open("")
      {:ok, stdout} = StringIO.open("")
      {:ok, stderr} = StringIO.open("")

      assert CLI.run(["-"], stdin: stdin, stdout: stdout, stderr: stderr) == 0
      assert {_input, ""} = StringIO.contents(stdout)
      assert {_input, ""} = StringIO.contents(stderr)
    end

    test "reports a stdin read error" do
      {:ok, stdin} = StringIO.open("First sentence.\n")
      {:ok, _contents} = StringIO.close(stdin)
      {:ok, stdout} = StringIO.open("")
      {:ok, stderr} = StringIO.open("")

      assert CLI.run(["-"], stdin: stdin, stdout: stdout, stderr: stderr) == 2
      assert {_input, output} = StringIO.contents(stderr)
      assert output =~ "could not read -"
    end

    test "rejects --write with stdin", %{tmp_dir: directory} do
      {:ok, stdin} = StringIO.open("First sentence. Second sentence.\n")
      {:ok, stderr} = StringIO.open("")

      status =
        File.cd!(directory, fn ->
          CLI.run(["--write", "-"], stdin: stdin, stderr: stderr)
        end)

      assert status == 2
      refute File.exists?(Path.join(directory, "-"))
      assert {_input, output} = StringIO.contents(stderr)
      assert output =~ "cannot use --write with stdin"
    end

    test "prints help" do
      {:ok, stdout} = StringIO.open("")
      {:ok, stderr} = StringIO.open("")

      assert CLI.run(["--help"], stdout: stdout, stderr: stderr) == 0
      assert {_input, output} = StringIO.contents(stdout)
      assert output =~ "Usage: adoc_formatter"
      assert output =~ "--write"
      assert output =~ "--check"
      assert {_input, ""} = StringIO.contents(stderr)
    end
  end
end
