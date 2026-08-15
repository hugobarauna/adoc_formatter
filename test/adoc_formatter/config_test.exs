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
  end
end
