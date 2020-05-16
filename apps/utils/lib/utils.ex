defmodule Utils do

  @doc """

  Given a term (and optionally a default term), attempt to coerce it
  into a binary. If not possible, then return error (or optional
  binary).

  Examples:

    iex> Utils.maybe_string(:a)
    {:ok, "a"}
  
    iex> Utils.maybe_string("a")
    {:ok, "a"}

    iex> Utils.maybe_string(1.0)
    {:ok, "1.0"}

    iex> Utils.maybe_string(1)
    {:ok, "1"}

    iex> Utils.maybe_string([97, 99, 'e'])
    {:ok, "ace"}

    iex> Utils.maybe_string(<<97, 99, 101>>)
    {:ok, "ace"}

    iex> Utils.maybe_string({})
    {:error, {:bad_type, {}}}

    iex> Utils.maybe_string({}, "not found")
    {:ok, "not found"}

    iex> Utils.maybe_string([97, 99, 10000000])
    {:error,
      {:parse_error, [97, 99, 10000000],
        %UnicodeConversionError{encoded: "ac", message: "invalid code point 10000000"}}}
  """
  @spec maybe_string(any, any) :: {:ok, binary} | {:ok, any} | {:error, {:parse_error, any, any}} | {:error, {:bad_type, any}}
  def maybe_string(v, default) do
    case maybe_string(v) do
      {:error, _} -> {:ok, default}
      ok -> ok
    end
  end
  @spec maybe_string(any) :: {:ok, binary} | {:error, any}
  def maybe_string(v) when is_atom(v), do: {:ok, Atom.to_string(v)}
  def maybe_string(v) when is_binary(v), do: {:ok, v}
  def maybe_string(v) when is_float(v), do: {:ok, Float.to_string(v)}
  def maybe_string(v) when is_integer(v), do: {:ok, Integer.to_string(v)}
  def maybe_string(v) when is_list(v) do
    try do
      {:ok, List.to_string(v)}
    rescue
      error -> {:error, {:parse_error, v, error}}
    end
  end
  def maybe_string(v), do: {:error, {:bad_type, v}}

  @doc """

  Given a term (and optionally a default term), attept to coerce it
  into an integer.  If not possible, then return an error (or the
  optional default binary).

  Examples:

    iex> Utils.maybe_integer(1)
    {:ok, 1}

    iex> Utils.maybe_integer(1.0)
    {:ok, 1}

    iex> Utils.maybe_integer(1.9999)
    {:ok, 1}

    iex> Utils.maybe_integer('1')
    {:ok, 1}

    iex> Utils.maybe_integer("1")
    {:ok, 1}

    iex> Utils.maybe_integer({})
    {:error, {:bad_type, {}}}

    iex> Utils.maybe_integer({}, "not found")
    {:ok, "not found"}

    iex> Utils.maybe_integer([1])
    {:error,
      {:parse_error, <<1>>,
        %ArgumentError{message: "argument error"}}}

  """

  @spec maybe_integer(any, any) :: {:ok, integer} | {:ok, any} | {:error, {:parse_error, any, any}} | {:error, {:bad_type, any}}
  def maybe_integer(v, default) do
    case maybe_integer(v) do
      {:error, _} -> {:ok, default}
      ok -> ok
    end
  end
  @spec maybe_integer(any) :: {:ok, integer} | {:error, any}
  def maybe_integer(v) when is_integer(v), do: {:ok, v}
  def maybe_integer(v) when is_float(v), do: {:ok, floor(v)}
  def maybe_integer(v) when is_list(v) do
    with {:ok, binary} <- maybe_string(v) do
      maybe_integer(binary)
    end
  end
  def maybe_integer(v) when is_binary(v) do
    try do
      {:ok, String.to_integer(v)}
    rescue
      error -> {:error, {:parse_error, v, error}}
    end
  end
  def maybe_integer(v), do: {:error, {:bad_type, v}}

  @doc """

  Given an enumerable and a transform function (which returns {:ok,
  transformed_value} | {atom, some_value}), return {:ok,
  transformed_enumerable} if all transformations were "ok".
  Otherwise, return {:error, map_of_transformations_with_errors}.

  Examples:

    iex> Utils.all_ok_transform(
    ...>    [1, 2],
    ...>    fn(v) ->
    ...>      if v>0 do
    ...>        {:ok, v * 2}
    ...>      else
    ...>        {:error, 0}
    ...>      end
    ...>    end
    ...> )
    {:ok, [2, 4]}

    iex> Utils.all_ok_transform(
    ...>    [1, 2, 0, -1],
    ...>    fn(v) ->
    ...>      if v>0 do
    ...>        {:ok, v * 2}
    ...>      else
    ...>        {:error, v}
    ...>      end
    ...>    end
    ...> )
    {:error, %{error: [0, -1], ok: [2, 4]}}
  
  """

  @spec all_ok_transform(Enum.T, (any -> {:ok, any} | {atom, any})) :: {:ok, Enum.T} | {:error, map}
  def all_ok_transform(enumerable, transform_f) do
    transformed = enumerable
    |> Enum.map(transform_f)
    |> Enum.group_by(fn({a, _}) -> a end, fn({_, v}) -> v end)
    |> Enum.into(%{:ok => []})

    if transformed |> Map.keys |> Enum.count != 1 do
      # if not all :ok
      {:error, transformed}
    else
      {:ok, transformed[:ok]}
    end
  end
end

