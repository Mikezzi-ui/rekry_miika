defmodule Rekry do
  @moduledoc """
  Reads MPEG-TS file and parses all MPEG-TS packet PID values from the file. Returns values as a list.

  Returns error tuple with reason, if reading file raises error.
  """

  @packet_size 188

  @doc """
    Reads through every byte in file until TS packet sync byte (0x47) is found. 
    After sync byte is found, function extracts TS packet PID and adds it to list.
    Function then skips rest of the bytes in TS packet and try to find next sync byte.

    Returns TS PID numbers as a list after whole file is read.
  """
  @spec parse_file(String.t()) :: list(integer())
  def parse_file(filename) do
    with {:ok, file} <- File.open(filename, [:read]),
         {:ok, stat} <- File.stat(filename) do
      pid_list = search_pid_numbers(file, stat.size)
      File.close(file)
      pid_list
    else
      {:error, reason} -> {:error, "Cannot open file!, message: #{reason}"}
    end
  end

  defp search_pid_numbers(file, file_size, read_pos \\ 0, pid_list \\ [])

  defp search_pid_numbers(_file, file_size, read_pos, pid_list) when read_pos >= file_size,
    do: pid_list

  defp search_pid_numbers(file, file_size, _read_pos, pid_list) do
    # IO.binread changes read position too. Compensated later in position changes.
    case IO.binread(file, 3) do
      <<0x47, _flags::size(3), pid::size(13)>> ->
        {:ok, new_read_pos} = :file.position(file, {:cur, @packet_size - 3})
        new_pid_list = pid_list ++ [pid]
        search_pid_numbers(file, file_size, new_read_pos, new_pid_list)

      _ ->
        {:ok, new_read_pos} = :file.position(file, {:cur, 1 - 3})
        search_pid_numbers(file, file_size, new_read_pos, pid_list)
    end
  end
end
