defmodule XmlBuilder do
  @moduledoc """
  A module for generating XML

  ## Examples

      iex> XmlBuilder.document(:person) |> XmlBuilder.generate
      "<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?>\\n<person/>"

      iex> XmlBuilder.document(:person, "Josh") |> XmlBuilder.generate
      "<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?>\\n<person>Josh</person>"

      iex> XmlBuilder.document(:person) |> XmlBuilder.generate(format: :none)
      "<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><person/>"

      iex> XmlBuilder.element(:person, "Josh") |> XmlBuilder.generate
      "<person>Josh</person>"

      iex> XmlBuilder.element(:person, %{occupation: "Developer"}, "Josh") |> XmlBuilder.generate
      "<person occupation=\\\"Developer\\\">Josh</person>"
  """

  defmacrop is_blank_attrs(attrs) do
    quote do: is_blank_map(unquote(attrs)) or is_blank_list(unquote(attrs))
  end

  defmacrop is_blank_list(list) do
    quote do: is_nil(unquote(list)) or unquote(list) == []
  end

  defmacrop is_blank_map(map) do
    quote do: is_nil(unquote(map)) or unquote(map) == %{}
  end

  @doc """
  Generate an XML document.

  Returns a `binary`.

  ## Examples

      iex> XmlBuilder.document(:person) |> XmlBuilder.generate
      "<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?>\\n<person/>"

      iex> XmlBuilder.document(:person, %{id: 1}) |> XmlBuilder.generate
      "<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?>\\n<person id=\\\"1\\\"/>"

      iex> XmlBuilder.document(:person, %{id: 1}, "some data") |> XmlBuilder.generate
      "<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?>\\n<person id=\\\"1\\\">some data</person>"
  """
  def document(elements),
    do: [:xml_decl | elements_with_prolog(elements) |> List.wrap()]

  def document(name, attrs_or_content),
    do: [:xml_decl | [element(name, attrs_or_content)]]

  def document(name, attrs, content),
    do: [:xml_decl | [element(name, attrs, content)]]

  @doc false
  def doc(elements) do
    IO.warn("doc/1 is deprecated. Use document/1 with generate/1 instead.")
    [:xml_decl | elements_with_prolog(elements) |> List.wrap()] |> generate
  end

  @doc false
  def doc(name, attrs_or_content) do
    IO.warn("doc/2 is deprecated. Use document/2 with generate/1 instead.")
    [:xml_decl | [element(name, attrs_or_content)]] |> generate
  end

  @doc false
  def doc(name, attrs, content) do
    IO.warn("doc/3 is deprecated. Use document/3 with generate/1 instead.")
    [:xml_decl | [element(name, attrs, content)]] |> generate
  end

  @doc """
  Create an XML element.

  Returns a `tuple` in the format `{name, attributes, content | list}`.

  ## Examples

      iex> XmlBuilder.element(:person)
      {:person, nil, nil}

      iex> XmlBuilder.element(:person, "data")
      {:person, nil, "data"}

      iex> XmlBuilder.element(:person, %{id: 1})
      {:person, %{id: 1}, nil}

      iex> XmlBuilder.element(:person, %{id: 1}, "data")
      {:person, %{id: 1}, "data"}

      iex> XmlBuilder.element(:person, %{id: 1}, [XmlBuilder.element(:first, "Steve"), XmlBuilder.element(:last, "Jobs")])
      {:person, %{id: 1}, [
        {:first, nil, "Steve"},
        {:last, nil, "Jobs"}
      ]}
  """
  def element(name) when is_bitstring(name),
    do: element({nil, nil, name})

  def element({:iodata, _data} = iodata),
    do: element({nil, nil, iodata})

  def element(name) when is_bitstring(name) or is_atom(name),
    do: element({name})

  def element(list) when is_list(list),
    do: list |> Enum.reject(&is_nil/1) |> Enum.map(&element/1)

  def element({name}),
    do: element({name, nil, nil})

  def element({name, attrs}) when is_map(attrs),
    do: element({name, attrs, nil})

  def element({name, content}),
    do: element({name, nil, content})

  def element({name, attrs, content}) when is_list(content),
    do: {name, attrs, element(content)}

  def element({name, attrs, content}),
    do: {name, attrs, content}

  def element(name, attrs) when is_map(attrs),
    do: element({name, attrs, nil})

  def element(name, content),
    do: element({name, nil, content})

  def element(name, attrs, content),
    do: element({name, attrs, content})

  @doc """
  Creates a DOCTYPE declaration with a system or public identifier.

  ## System Example

  Returns a `tuple` in the format `{:doctype, {:system, name, system_identifier}}`.

  ```elixir
  import XmlBuilder

  document([
    doctype("greeting", system: "hello.dtd"),
    element(:person, "Josh")
  ]) |> generate
  ```

  Outputs

  ```xml
  <?xml version="1.0" encoding="UTF-8" ?>
  <!DOCTYPE greeting SYSTEM "hello.dtd">
  <person>Josh</person>
  ```

  ## Public Example

   Returns a `tuple` in the format `{:doctype, {:public, name, public_identifier, system_identifier}}`.

  ```elixir
  import XmlBuilder

  document([
    doctype("html", public: ["-//W3C//DTD XHTML 1.0 Transitional//EN",
                  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"]),
    element(:html, "Hello, world!")
  ]) |> generate
  ```

  Outputs

  ```xml
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
  <html>Hello, world!</html>
  ```
  """
  def doctype(name, [{:system, system_identifier}]),
    do: {:doctype, {:system, name, system_identifier}}

  def doctype(name, [{:public, [public_identifier, system_identifier]}]),
    do: {:doctype, {:public, name, public_identifier, system_identifier}}

  @doc """
  Generate a binary from an XML tree

  Returns a `binary`.

  ## Examples

      iex> XmlBuilder.generate(XmlBuilder.element(:person))
      "<person/>"

      iex> XmlBuilder.generate({:person, %{id: 1}, "Steve Jobs"})
      "<person id=\\\"1\\\">Steve Jobs</person>"

      iex> XmlBuilder.generate({:name, nil, [{:first, nil, "Steve"}]}, format: :none)
      "<name><first>Steve</first></name>"

      iex> XmlBuilder.generate({:name, nil, [{:first, nil, "Steve"}]}, whitespace: "")
      "<name>\\n<first>Steve</first>\\n</name>"

      iex> XmlBuilder.generate({:name, nil, [{:first, nil, "Steve"}]})
      "<name>\\n  <first>Steve</first>\\n</name>"

      iex> XmlBuilder.generate(:xml_decl, encoding: "ISO-8859-1")
      ~s|<?xml version="1.0" encoding="ISO-8859-1"?>|
  """
  def generate(any, options \\ []),
    do: format(any, 0, options) |> IO.iodata_to_binary()

  @doc """
  Similar to `generate/2`, but returns `iodata` instead of a `binary`.

  ## Examples

      iex> XmlBuilder.generate_iodata(XmlBuilder.element(:person))
      ["", '<', "person", '/>']
  """
  def generate_iodata(any, options \\ []), do: format(any, 0, options)

  defp format(:xml_decl, 0, options) do
    encoding = Keyword.get(options, :encoding, "UTF-8")

    standalone =
      case Keyword.get(options, :standalone, nil) do
        true -> ~s| standalone="yes"|
        false -> ~s| standalone="no"|
        nil -> ""
      end

    [~c"<?xml version=\"1.0\" encoding=\"", to_string(encoding), ?", standalone, ~c"?>"]
  end

  defp format({:doctype, {:system, name, system}}, 0, _options),
    do: [~c"<!DOCTYPE ", to_string(name), ~c" SYSTEM \"", to_string(system), ~c"\">"]

  defp format({:doctype, {:public, name, public, system}}, 0, _options),
    do: [
      ~c"<!DOCTYPE ",
      to_string(name),
      ~c" PUBLIC \"",
      to_string(public),
      ~c"\" \"",
      to_string(system),
      ~c"\">"
    ]

  defp format(string, level, options) when is_bitstring(string),
    do: format({nil, nil, string}, level, options)

  defp format(list, level, options) when is_list(list) do
    format_children(list, level, options)
  end

  defp format({nil, nil, name}, level, options) when is_bitstring(name),
    do: [indent(level, options), to_string(name)]

  defp format({nil, nil, {:iodata, iodata}}, _level, _options), do: iodata

  defp format({name, attrs, content}, level, options)
       when is_blank_attrs(attrs) and is_blank_list(content),
       do: [indent(level, options), ~c"<", to_string(name), ~c"/>"]

  defp format({name, attrs, content}, level, options) when is_blank_list(content),
    do: [indent(level, options), ~c"<", to_string(name), ~c" ", format_attributes(attrs), ~c"/>"]

  defp format({name, attrs, content}, level, options)
       when is_blank_attrs(attrs) and not is_list(content),
       do: [
         indent(level, options),
         ~c"<",
         to_string(name),
         ~c">",
         format_content(content, level + 1, options),
         ~c"</",
         to_string(name),
         ~c">"
       ]

  defp format({name, attrs, content}, level, options)
       when is_blank_attrs(attrs) and is_list(content) do
    format_char = formatter(options).line_break()

    [
      indent(level, options),
      ~c"<",
      to_string(name),
      ~c">",
      format_content(content, level + 1, options),
      format_char,
      indent(level, options),
      ~c"</",
      to_string(name),
      ~c">"
    ]
  end

  defp format({name, attrs, content}, level, options)
       when not is_blank_attrs(attrs) and not is_list(content),
       do: [
         indent(level, options),
         ~c"<",
         to_string(name),
         ~c" ",
         format_attributes(attrs),
         ~c">",
         format_content(content, level + 1, options),
         ~c"</",
         to_string(name),
         ~c">"
       ]

  defp format({name, attrs, content}, level, options)
       when not is_blank_attrs(attrs) and is_list(content) do
    format_char = formatter(options).line_break()

    [
      indent(level, options),
      ~c"<",
      to_string(name),
      ~c" ",
      format_attributes(attrs),
      ~c">",
      format_content(content, level + 1, options),
      format_char,
      indent(level, options),
      ~c"</",
      to_string(name),
      ~c">"
    ]
  end

  defp format_children(list, level, options) when is_list(list) do
    format_char = formatter(options).line_break()

    {result, _} =
      Enum.flat_map_reduce(list, 0, fn
        elm, count when is_blank_list(elm) ->
          {[], count}

        elm, count ->
          if format_char == "" or count == 0 do
            {[format(elm, level, options)], count + 1}
          else
            {[format_char, format(elm, level, options)], count + 1}
          end
      end)

    result
  end

  defp elements_with_prolog([first | rest]) when length(rest) > 0,
    do: [first_element(first) | element(rest)]

  defp elements_with_prolog(element_spec),
    do: element(element_spec)

  defp first_element({:doctype, args} = doctype_decl) when is_tuple(args),
    do: doctype_decl

  defp first_element(element_spec),
    do: element(element_spec)

  defp formatter(options) do
    case Keyword.get(options, :format) do
      :none -> XmlBuilder.Format.None
      _ -> XmlBuilder.Format.Indented
    end
  end

  defp format_content(children, level, options) when is_list(children) do
    format_char = formatter(options).line_break()
    [format_char, format_children(children, level, options)]
  end

  defp format_content(content, _level, _options),
    do: escape(content)

  defp format_attributes(attrs),
    do:
      map_intersperse(attrs, " ", fn {name, value} ->
        [to_string(name), ~c"=", quote_attribute_value(value)]
      end)

  defp indent(level, options) do
    formatter = formatter(options)
    formatter.indentation(level, options)
  end

  defp quote_attribute_value(val) when not is_bitstring(val),
    do: quote_attribute_value(to_string(val))

  defp quote_attribute_value(val) do
    escape? = String.contains?(val, ["\"", "&", "<"])

    case escape? do
      true -> [?", escape(val), ?"]
      false -> [?", val, ?"]
    end
  end

  defp escape({:iodata, iodata}), do: iodata
  defp escape({:safe, data}) when is_bitstring(data), do: data
  defp escape({:safe, data}), do: to_string(data)
  defp escape({:cdata, data}), do: ["<![CDATA[", data, "]]>"]

  defp escape(data) when is_binary(data),
    do: data |> escape_string() |> to_string()

  defp escape(data) when not is_bitstring(data),
    do: data |> to_string() |> escape_string() |> to_string()

  defp escape_string(""), do: ""
  defp escape_string(<<"&"::utf8, rest::binary>>), do: escape_entity(rest)
  defp escape_string(<<"<"::utf8, rest::binary>>), do: ["&lt;" | escape_string(rest)]
  defp escape_string(<<">"::utf8, rest::binary>>), do: ["&gt;" | escape_string(rest)]
  defp escape_string(<<"\""::utf8, rest::binary>>), do: ["&quot;" | escape_string(rest)]
  defp escape_string(<<"'"::utf8, rest::binary>>), do: ["&apos;" | escape_string(rest)]
  defp escape_string(<<c::utf8, rest::binary>>), do: [c | escape_string(rest)]

  defp escape_entity(<<"amp;"::utf8, rest::binary>>), do: ["&amp;" | escape_string(rest)]
  defp escape_entity(<<"lt;"::utf8, rest::binary>>), do: ["&lt;" | escape_string(rest)]
  defp escape_entity(<<"gt;"::utf8, rest::binary>>), do: ["&gt;" | escape_string(rest)]
  defp escape_entity(<<"quot;"::utf8, rest::binary>>), do: ["&quot;" | escape_string(rest)]
  defp escape_entity(<<"apos;"::utf8, rest::binary>>), do: ["&apos;" | escape_string(rest)]
  defp escape_entity(rest), do: ["&amp;" | escape_string(rest)]

  # Remove when support for Elixir <v1.10 is dropped
  @compile {:inline, map_intersperse: 3}
  if function_exported?(Enum, :map_intersperse, 3) do
    defp map_intersperse(enumerable, separator, mapper),
      do: Enum.map_intersperse(enumerable, separator, mapper)
  else
    defp map_intersperse(enumerable, separator, mapper),
      do: enumerable |> Enum.map(mapper) |> Enum.intersperse(separator)
  end
end
