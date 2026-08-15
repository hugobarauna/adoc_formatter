# adoc_formatter

An experimental, source-preserving AsciiDoc formatter written in Elixir.

The first feature implements Asciidoctor's
[One Sentence Per Line](https://github.com/asciidoctor/asciidoctor.org/blob/main/docs/asciidoc-recommended-practices.adoc#one-sentence-per-line)
recommendation. It joins existing soft-wrapped prose and writes each sentence on
its own source line while leaving structural and whitespace-sensitive AsciiDoc
blocks untouched.

## Build

The project requires Elixir 1.17 or later.

```sh
mix deps.get
mix escript.build
```

This creates an `adoc_formatter` executable in the project directory.

## Use locally

Preview the formatted result on stdout:

```sh
./adoc_formatter chapter.adoc
```

Format one or more files, directories, or globs in place:

```sh
./adoc_formatter --write chapter.adoc
./adoc_formatter --write chapters front_matter parts
./adoc_formatter --write 'chapters/**/*.adoc'
```

Check whether any files need formatting without changing them:

```sh
./adoc_formatter --check chapters front_matter parts
```

`--check` exits with status `1` and prints each file that would change. Invalid
arguments or unreadable files exit with status `2`.

## Configure sentence exceptions

Create `.adoc_formatter.exs` in the directory where the command runs:

```elixir
[
  non_breaking_phrases: [
    "Yahoo! Finance",
    "Dr.",
    "Drs.",
    "St.",
    "p."
  ]
]
```

These exact phrases will not be split internally. Use another config location
with `--config PATH`.

## Editor integration

The formatter can read from stdin and write to stdout, which is the interface
many editors expect:

```sh
./adoc_formatter - < chapter.adoc
```

Editors that support a format-on-save command can instead invoke
`adoc_formatter --write` with the current file path.

## Current scope

The formatter recognizes prose without regenerating the document from an AST.
It changes only paragraph whitespace and deliberately leaves source, listing,
literal, passthrough, comment, table, and verse content untouched. Paragraphs
that contain an explicit AsciiDoc hard line break (` +`) are also left as-is.

The local formatter is the first deliverable. Repository and CI integration can
be added later once the workflow is accepted.
