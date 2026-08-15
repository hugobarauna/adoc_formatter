defmodule AdocFormatterTest do
  use ExUnit.Case

  describe "format/2" do
    test "puts each sentence on its own line" do
      source = "First sentence. Second sentence.\n"

      assert AdocFormatter.format(source) == "First sentence.\nSecond sentence.\n"
    end

    test "joins an existing soft wrap within a sentence" do
      source = "A sentence that was\nsoft wrapped. Another sentence.\n"

      assert AdocFormatter.format(source) ==
               "A sentence that was soft wrapped.\nAnother sentence.\n"
    end

    test "preserves blank lines between paragraphs" do
      source = "First paragraph. Another sentence.\n\nSecond paragraph. Its next sentence.\n"

      assert AdocFormatter.format(source) ==
               "First paragraph.\nAnother sentence.\n\nSecond paragraph.\nIts next sentence.\n"
    end

    test "does not format a document title" do
      source = "= Why now? A practical guide\n\nFirst sentence. Second sentence.\n"

      assert AdocFormatter.format(source) ==
               "= Why now? A practical guide\n\nFirst sentence.\nSecond sentence.\n"
    end

    test "indents later sentences within a list item" do
      source = "* First sentence. Second sentence.\n* Another item. Its second sentence.\n"

      assert AdocFormatter.format(source) ==
               "* First sentence.\n  Second sentence.\n* Another item.\n  Its second sentence.\n"
    end

    test "keeps configured phrases from creating sentence boundaries" do
      source = "Yahoo! Finance provides the data. Another sentence.\n"

      assert AdocFormatter.format(source, non_breaking_phrases: ["Yahoo! Finance"]) ==
               "Yahoo! Finance provides the data.\nAnother sentence.\n"
    end

    test "does not match a configured phrase inside a larger word" do
      source = "These questions are deep. We promise you.\n"

      assert AdocFormatter.format(source, non_breaking_phrases: ["p."]) ==
               "These questions are deep.\nWe promise you.\n"
    end

    test "does not treat initials as sentence boundaries" do
      source = "* Asness, C. S., & Liew, J. M. (2001). Do hedge funds hedge?.\n"

      assert AdocFormatter.format(source) ==
               "* Asness, C. S., & Liew, J. M. (2001).\n  Do hedge funds hedge?.\n"
    end

    test "does not split on punctuation inside inline monospace" do
      source = "Use `first. second?` carefully. Another sentence.\n"

      assert AdocFormatter.format(source) ==
               "Use `first. second?` carefully.\nAnother sentence.\n"
    end

    test "does not split on punctuation inside an inline macro" do
      source =
        "Read link:https://example.com[Why now? Learn more.] before continuing. Next sentence.\n"

      assert AdocFormatter.format(source) ==
               "Read link:https://example.com[Why now? Learn more.] before continuing.\nNext sentence.\n"
    end

    test "does not split on punctuation inside a targetless inline macro" do
      source = "A claim.footnote:[Supporting detail. Another detail.] Next sentence.\n"

      assert AdocFormatter.format(source) ==
               "A claim.footnote:[Supporting detail. Another detail.]\nNext sentence.\n"
    end

    test "keeps an empty attribute attached to a following footnote" do
      source = "A claim.{empty}footnote:[Supporting detail. Another detail.] Next sentence.\n"

      assert AdocFormatter.format(source) ==
               "A claim.{empty}footnote:[Supporting detail. Another detail.]\nNext sentence.\n"
    end

    test "moves an exclamation boundary past an attached footnote" do
      source = "A claim!{empty}footnote:[Supporting detail.] Next sentence.\n"

      assert AdocFormatter.format(source) ==
               "A claim!{empty}footnote:[Supporting detail.]\nNext sentence.\n"
    end

    test "preserves soft-wrap whitespace before an empty attribute" do
      source = "A claim!\n{empty}footnote:[Supporting detail.] Next sentence.\n"

      assert AdocFormatter.format(source) ==
               "A claim! {empty}footnote:[Supporting detail.]\nNext sentence.\n"
    end

    test "keeps an inline formatting closer with its sentence" do
      source = "This is *important.* Next sentence.\n"

      assert AdocFormatter.format(source) == "This is *important.*\nNext sentence.\n"
    end

    test "keeps a formatting closer after a closing quote with its sentence" do
      source = "Consider _“Why now?”_ before continuing. Next sentence.\n"

      assert AdocFormatter.format(source) ==
               "Consider _“Why now?”_ before continuing.\nNext sentence.\n"
    end

    test "does not split terminal punctuation inside a mid-sentence parenthetical" do
      exclamation =
        "We will cover this extensively (and you will practice it!) in Chapter 14. Next sentence.\n"

      question =
        "Markets are noisy (or is it information?) and can overload investors. Next sentence.\n"

      assert AdocFormatter.format(exclamation) ==
               "We will cover this extensively (and you will practice it!) in Chapter 14.\nNext sentence.\n"

      assert AdocFormatter.format(question) ==
               "Markets are noisy (or is it information?) and can overload investors.\nNext sentence.\n"
    end

    test "does not split an ellipsis joined to the following word" do
      source = "The quote begins \"...Start here.\" Next sentence.\n"

      assert AdocFormatter.format(source) ==
               "The quote begins \"...Start here.\"\nNext sentence.\n"
    end

    test "does not split after an opening quotation ellipsis" do
      source = "In his words, \"... In a dynamic landscape, speed wins.\" Next sentence.\n"

      assert AdocFormatter.format(source) ==
               "In his words, \"... In a dynamic landscape, speed wins.\"\nNext sentence.\n"
    end

    test "does not split at a non-breaking space" do
      source = "First sentence.\u00A0_Still attached._ Next sentence.\n"

      assert AdocFormatter.format(source) ==
               "First sentence.\u00A0_Still attached._\nNext sentence.\n"
    end

    test "does not split at a sentence boundary with no whitespace in the source" do
      source = ~s(He said "Stop."She left quickly. Next sentence.\n)

      assert AdocFormatter.format(source) ==
               ~s(He said "Stop."She left quickly.\nNext sentence.\n)
    end

    test "keeps consecutive terminal punctuation together" do
      source = "Is this correct?. Next sentence.\n"

      assert AdocFormatter.format(source) == "Is this correct?.\nNext sentence.\n"
    end

    test "does not split consecutive punctuation before a non-breaking space" do
      source = "Is this correct?.\u00A0_Still attached._ Next sentence.\n"

      assert AdocFormatter.format(source) ==
               "Is this correct?.\u00A0_Still attached._\nNext sentence.\n"
    end

    test "leaves a paragraph with an explicit hard line break unchanged" do
      source = "First visible line. +\nSecond visible line. Another sentence.\n"

      assert AdocFormatter.format(source) == source
    end

    test "preserves CRLF line endings" do
      source = "First sentence. Second sentence.\r\n"

      assert AdocFormatter.format(source) == "First sentence.\r\nSecond sentence.\r\n"
    end

    test "formats already formatted output unchanged" do
      sources = [
        "First sentence. Second sentence.\n",
        "* First sentence. Second one here.\n* Another item. Its second sentence.\n",
        "Low:: First sentence. Second sentence.\nHigh:: Another item. Next sentence.\n",
        "= Title\n\nA claim.footnote:[Detail. More.] Next sentence.\n\n----\ncode. keep.\n----\n",
        "NOTE: One sentence. Two sentences.\n",
        "First sentence. Second sentence.\r\n",
        "No trailing newline. Second sentence.",
        ~s(He said "Stop."She left quickly. Next sentence.\n),
        "<1> First sentence. Second sentence.\n<2> Another item. Next sentence.\n"
      ]

      for source <- sources do
        formatted = AdocFormatter.format(source)

        assert AdocFormatter.format(formatted) == formatted
      end
    end
  end
end
