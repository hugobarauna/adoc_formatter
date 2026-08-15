defmodule AdocFormatter.ConfigTest do
  use ExUnit.Case

  alias AdocFormatter.Config

  describe "load/1" do
    @describetag :tmp_dir

    test "loads formatter options from an Elixir config file", %{tmp_dir: directory} do
      path = Path.join(directory, ".adoc_formatter.exs")
      File.write!(path, ~S([non_breaking_phrases: ["Yahoo! Finance", "Dr."]]))

      assert Config.load(path) ==
               {:ok, non_breaking_phrases: ["Yahoo! Finance", "Dr."]}
    end

    test "rejects options that do not match the supported config", %{tmp_dir: directory} do
      path = Path.join(directory, ".adoc_formatter.exs")
      File.write!(path, ~S(%{non_breaking_phrases: "Yahoo! Finance"}))

      assert {:error, message} = Config.load(path)
      assert message =~ "expected a keyword list"
    end

    test "rejects unsupported option keys", %{tmp_dir: directory} do
      path = Path.join(directory, ".adoc_formatter.exs")
      File.write!(path, ~S([line_length: 80]))

      assert Config.load(path) == {:error, "formatter config contains unsupported options"}
    end

    test "rejects phrases that are not strings", %{tmp_dir: directory} do
      path = Path.join(directory, ".adoc_formatter.exs")
      File.write!(path, ~S([non_breaking_phrases: [:dr]]))

      assert Config.load(path) == {:error, "non_breaking_phrases must be a list of strings"}
    end

    test "reports a config file that cannot be loaded", %{tmp_dir: directory} do
      path = Path.join(directory, "missing.exs")

      assert {:error, message} = Config.load(path)
      assert message =~ "could not load #{path}"
    end
  end
end
