import SweetXml

defmodule CiTestTimingSplitter do
  def main(args \\ []) do
    args
    |> parse_args
    |> build_timings_hash
    |> do_greedy_number_partitioning
    |> respond
  end

  defp parse_args(args) do
    {opts, _, _} =
      args
      |> OptionParser.parse(
        strict: [
          timings_directory: :string,
          machine_count: :integer,
          machine_index: :integer
        ],
        aliases: [
          d: :timings_directory,
          c: :machine_count,
          i: :machine_index
        ]
      )

    %{timings_directory: d, machine_count: c, machine_index: i} =
      opts
      |> Enum.into(%{})
      |> Map.put_new(:machine_index, nil)

    {d, c, i}
  end

  defp build_timings_hash({timings_directory, machine_count, machine_index}) do
    timings =
      "#{timings_directory}/*.xml"
      |> Path.wildcard()
      |> Task.async_stream(fn file ->
        file
        |> File.read()
        |> (fn {:ok, xmldoc} ->
              {
                xmldoc |> xpath(~x"//testsuite/@time"f),
                xmldoc |> xpath(~x"//testsuite/testcase[1]/@file"s)
              }
            end).()
      end)
      |> Enum.map(&elem(&1, 1))
      |> Enum.sort_by(fn {timing, _} -> timing end, &>=/2)

    {timings, machine_count, machine_index}
  end

  defp do_greedy_number_partitioning({timings, machine_count, machine_index}) do
    partitions =
      for index <- 1..machine_count,
          do: {index - 1, 0, []}

    {partitioned_tests, _} =
      timings
      |> Enum.reduce(
        {partitions, 0},
        fn {timing, filename}, {partitions, smallest_index} ->
          {index, duration, files} = Enum.at(partitions, smallest_index)

          new_partitions =
            partitions
            |> List.replace_at(
              smallest_index,
              {index, duration + timing, [{timing, filename} | files]}
            )

          {new_smallest_index, _} =
            new_partitions
            |> Enum.reduce({smallest_index, duration + timing}, fn
              {index, duration, _}, {min_index, min_duration} ->
                case duration < min_duration do
                  true -> {index, duration}
                  false -> {min_index, min_duration}
                end
            end)

          {new_partitions, new_smallest_index}
        end
      )

    {partitioned_tests, machine_index}
  end

  defp respond({partitioned_tests, machine_index}) when is_integer(machine_index) do
    partitioned_tests
    |> Enum.find(fn {index, _, _} -> index == machine_index end)
    |> elem(2)
    |> Enum.map(&elem(&1, 1))
    |> IO.puts()
  end

  defp respond({partitioned_tests, _}) do
    partitioned_tests
    |> Enum.map(&Tuple.to_list(&1))
    |> Enum.map(fn [index, duration, files] ->
      [index, duration, Enum.reduce(files, "", fn {duration, filename}, acc -> "#{duration} - #{filename}\n#{acc}" end)]
    end)
    |> TableRex.quick_render!()
    |> IO.puts
  end
end
