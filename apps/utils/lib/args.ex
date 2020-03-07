defmodule Args do
  def atom_to_name(atom) do
    name = atom
    |> Atom.to_string
    |> String.replace("_", "-")
    if name |> String.length > 2 do
      "--#{name}"
    else
      "-#{name}"
    end
  end
  
  def prepare_arg(atom, _opts) when is_atom(atom) do
    {:ok, ["#{atom_to_name(atom)}"]}
  end
  def prepare_arg({atom, value}, opts) when is_atom(atom) do
    {"#{atom_to_name(atom)}", value}
    |> prepare_arg(opts)
  end
  def prepare_arg({name, tuple}, opts) when is_tuple(tuple) do
    {name, Tuple.to_list(tuple)}
    |> prepare_arg(opts)
  end
  def prepare_arg({name, []}, _opts), do: {:error, {:empty_list_arg, name}}
  def prepare_arg({name, list}, opts) when is_list(list) do
    import Utils
    with {:ok, sep} <- maybe_string(Keyword.get(opts, :sep, ",")) do
      case all_ok_transform(list, &maybe_string/1) do
        {:ok, strings} ->
          {name, strings |> Enum.join(sep)}
          |> prepare_arg(opts)
        {:error, error} -> {:error, {:bad_list, name, list, error[:error]}}
      end
    end
  end
  def prepare_arg({name, integer}, opts) when is_integer(integer) do
    {name, Integer.to_string(integer)}
    |> prepare_arg(opts)
  end
  def prepare_arg({name, value}, _opts) do
    with {:ok, name} <- Utils.maybe_string(name),
         {:ok, value} <- Utils.maybe_string(value) do
      {:ok, [name, value]}
    else
      error -> {:error, {:not_string_like, error}}
    end
  end
  # def prepare_arg({name, value}, _opts) when is_binary(name) and is_binary(value) do
  #   {:ok, ["#{name}","#{value}"]}
  # end
  def prepare_arg(string, _opts) when is_binary(string), do: {:ok, [string]}
  def prepare_arg(bad, _opts), do: {:error, {:cannot_parse_arg, bad}}

  def from_list(list, opts\\[]) when is_list(list) do
    args = list
    |> Enum.map(&prepare_arg(&1, opts))
    |> Enum.group_by(fn({atom, _}) -> atom end)

    error = Map.get(args, :error, [])
    if error |> Enum.count > 0 do
      IO.inspect(error)
      {:error, {:bad_args, error}}
    else
      {:ok,
       args[:ok]
       |> Enum.map(fn({:ok, v}) -> v end)
       |> Enum.concat
       # |> IO.inspect
       # |> Enum.join(" ")
      }
    end
  end
  
end


