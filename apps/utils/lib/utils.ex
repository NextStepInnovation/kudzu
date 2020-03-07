defmodule Utils do
  @spec maybe_string(any, any) :: {:ok, binary} | {:ok, any}
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
  

  @spec maybe_integer(any, any) :: {:ok, integer} | {:ok, any}
  def maybe_integer(v, default) do
    case maybe_integer(v) do
      {:error, _} -> {:ok, default}
      ok -> ok
    end
  end
  @spec maybe_integer(any) :: {:ok, integer} | {:error, any}
  def maybe_integer(v) when is_integer(v), do: {:ok, v}
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

  def all_ok_transform(enumerable, transform_f) do
    transformed = enumerable
    |> Enum.map(transform_f)
    |> Enum.group_by(fn({a, _}) -> a end, fn({_, v}) -> v end)
    |> Enum.into(%{:ok => []})

    if Enum.count(transformed[:ok]) != Enum.count(enumerable) do
      {:error, transformed}
    else
      {:ok, transformed[:ok]}
    end
  end
end

