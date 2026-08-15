defmodule AdocFormatter.ScannerTest do
  use ExUnit.Case

  alias AdocFormatter.Scanner

  describe "scan/1" do
    test "marks a document title as raw and a paragraph as prose" do
      source = "= Book title\n\nFirst sentence. Second sentence.\n"

      assert Scanner.scan(source) == [
               {:raw, "= Book title\n"},
               {:raw, "\n"},
               {:prose, "First sentence. Second sentence.\n",
                %{continuation_prefix: "", prefix: ""}}
             ]
    end

    test "marks a delimited source block as raw" do
      source =
        "[source,elixir]\n----\nIO.puts(\"First. Second.\")\n----\n\nAfterward. Next.\n"

      assert Scanner.scan(source) == [
               {:raw, "[source,elixir]\n"},
               {:raw, "----\n"},
               {:raw, "IO.puts(\"First. Second.\")\n"},
               {:raw, "----\n"},
               {:raw, "\n"},
               {:prose, "Afterward. Next.\n", %{continuation_prefix: "", prefix: ""}}
             ]
    end

    test "keeps prose inside an example block eligible for formatting" do
      source = "====\nFirst sentence. Second sentence.\n====\n"

      assert Scanner.scan(source) == [
               {:raw, "====\n"},
               {:prose, "First sentence. Second sentence.\n",
                %{continuation_prefix: "", prefix: ""}},
               {:raw, "====\n"}
             ]
    end

    test "marks a literal block as raw" do
      source = "....\nLiteral text. Keep this line.\n....\n"

      assert Scanner.scan(source) == [
               {:raw, "....\n"},
               {:raw, "Literal text. Keep this line.\n"},
               {:raw, "....\n"}
             ]
    end

    test "requires the exact variable-length delimiter to close an opaque block" do
      source =
        "--------\nCode. Keep this.\n----\nStill code. Keep this.\n--------\nAfter. Next.\n"

      assert Scanner.scan(source) == [
               {:raw, "--------\n"},
               {:raw, "Code. Keep this.\n"},
               {:raw, "----\n"},
               {:raw, "Still code. Keep this.\n"},
               {:raw, "--------\n"},
               {:prose, "After. Next.\n", %{continuation_prefix: "", prefix: ""}}
             ]
    end

    test "marks a table as raw" do
      source = "|===\n|Cell one. Cell two.\n|===\n"

      assert Scanner.scan(source) == [
               {:raw, "|===\n"},
               {:raw, "|Cell one. Cell two.\n"},
               {:raw, "|===\n"}
             ]
    end

    test "marks a passthrough block as raw" do
      source = "++++\n<p>First. Second.</p>\n++++\n"

      assert Scanner.scan(source) == [
               {:raw, "++++\n"},
               {:raw, "<p>First. Second.</p>\n"},
               {:raw, "++++\n"}
             ]
    end

    test "marks a comment block as raw" do
      source = "////\nEditorial note. Keep together.\n////\n"

      assert Scanner.scan(source) == [
               {:raw, "////\n"},
               {:raw, "Editorial note. Keep together.\n"},
               {:raw, "////\n"}
             ]
    end

    test "keeps prose inside a sidebar eligible for formatting" do
      source = "****\nFirst sentence. Second sentence.\n****\n"

      assert Scanner.scan(source) == [
               {:raw, "****\n"},
               {:prose, "First sentence. Second sentence.\n",
                %{continuation_prefix: "", prefix: ""}},
               {:raw, "****\n"}
             ]
    end

    test "keeps prose inside a quote block eligible for formatting" do
      source = "____\nFirst sentence. Second sentence.\n____\n"

      assert Scanner.scan(source) == [
               {:raw, "____\n"},
               {:prose, "First sentence. Second sentence.\n",
                %{continuation_prefix: "", prefix: ""}},
               {:raw, "____\n"}
             ]
    end

    test "returns each bullet item as prose with its marker metadata" do
      source = "* First sentence. Second sentence.\n* Third sentence. Fourth sentence.\n"

      assert Scanner.scan(source) == [
               {:prose, "* First sentence. Second sentence.\n",
                %{continuation_prefix: "  ", prefix: "* "}},
               {:prose, "* Third sentence. Fourth sentence.\n",
                %{continuation_prefix: "  ", prefix: "* "}}
             ]
    end

    test "marks a verse block as raw because its line breaks are significant" do
      source = "[verse, Author]\n____\nFirst line;\nsecond line.\n____\n"

      assert Scanner.scan(source) == [
               {:raw, "[verse, Author]\n"},
               {:raw, "____\n"},
               {:raw, "First line;\n"},
               {:raw, "second line.\n"},
               {:raw, "____\n"}
             ]
    end

    test "marks a block title as raw" do
      source = ".Why now? A practical note\nFirst sentence. Second sentence.\n"

      assert Scanner.scan(source) == [
               {:raw, ".Why now? A practical note\n"},
               {:prose, "First sentence. Second sentence.\n",
                %{continuation_prefix: "", prefix: ""}}
             ]
    end

    test "returns each callout item as prose with its marker metadata" do
      source = "<1> First sentence. Second sentence.\n<2> Another item. Next sentence.\n"

      assert Scanner.scan(source) == [
               {:prose, "<1> First sentence. Second sentence.\n",
                %{continuation_prefix: "    ", prefix: "<1> "}},
               {:prose, "<2> Another item. Next sentence.\n",
                %{continuation_prefix: "    ", prefix: "<2> "}}
             ]
    end

    test "returns each description-list item as separate prose" do
      source = "Low:: First sentence. Second sentence.\nHigh:: Another item. Next sentence.\n"

      assert Scanner.scan(source) == [
               {:prose, "Low:: First sentence. Second sentence.\n",
                %{continuation_prefix: "", prefix: "Low:: "}},
               {:prose, "High:: Another item. Next sentence.\n",
                %{continuation_prefix: "", prefix: "High:: "}}
             ]
    end

    test "marks AsciiDoc control lines as raw" do
      lines = [
        "// A comment. Keep it intact.\n",
        ":attribute: A value. Keep it intact.\n",
        "include::chapter.adoc[]\n",
        "ifdef::backend-pdf[]\n",
        "endif::[]\n",
        "image::figure.png[A caption? Keep it intact.]\n",
        "<<<\n",
        "+\n",
        "[[an-anchor]]\n"
      ]

      assert Scanner.scan(Enum.join(lines)) == Enum.map(lines, &{:raw, &1})
    end

    test "marks an indented literal paragraph as raw" do
      source = "  Literal code. Keep this line.\n  Another literal line.\n"

      assert Scanner.scan(source) == [
               {:raw, "  Literal code. Keep this line.\n"},
               {:raw, "  Another literal line.\n"}
             ]
    end

    test "marks Markdown-style quote lines as raw" do
      source = "> First quoted line.\n> Second quoted line.\n> -- Attribution\n"

      assert Scanner.scan(source) == [
               {:raw, "> First quoted line.\n"},
               {:raw, "> Second quoted line.\n"},
               {:raw, "> -- Attribution\n"}
             ]
    end
  end
end
