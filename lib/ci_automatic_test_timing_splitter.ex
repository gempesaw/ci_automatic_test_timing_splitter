import SweetXml

defmodule CiAutomaticTestTimingSplitter do
  def main(args \\ []) do
    {timings, count, index} =
      args
      |> parse_args
      |> build_timings_hash

    case count do
      nil ->
        determine_optimal_parallel({timings, 2, index})

      _ ->
        do_greedy_number_partitioning({timings, count, index})
    end
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
      |> Map.put_new(:machine_count, nil)
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
      |> Enum.map(fn {:ok, {timing, filename} } -> {timing |> Float.round(1), filename} end)
      |> Enum.sort_by(fn {timing, _} -> timing end, &>=/2)

    {timings, machine_count, machine_index}
  end

  defp do_greedy_number_partitioning({timings, machine_count, machine_index}) do
    partitions =
      for index <- 1..machine_count,
          do: {index - 1, 0, []}

    partitioned_tests =
      timings
      |> Enum.reduce(partitions, fn {timing, filename}, acc_partitions ->
        {smallest_index, _} =
          acc_partitions
          |> Enum.reduce(fn {index, duration, _}, acc ->
            {min_index, min_duration} = {elem(acc, 0), elem(acc, 1)}

            case duration < min_duration do
              true -> {index, duration}
              false -> {min_index, min_duration}
            end
          end)

        {index, duration, files} = Enum.at(acc_partitions, smallest_index)

        acc_partitions
        |> List.replace_at(
          smallest_index,
          {index, duration + timing, [{timing, filename} | files]}
        )
      end)

    {partitioned_tests, machine_index}
  end

  defp determine_optimal_parallel(
         {timings, machine_count, machine_index},
         {partitioned_tests, _} \\ {[], nil}
       ) do
    [{max_duration, _} | _] = timings
    reversed = partitioned_tests |> Enum.reverse()

    case reversed do
      [] ->
        IO.puts(:stderr, "the longest single test runs for #{max_duration |> Float.round(1)} seconds. trying with #{machine_count} groups...")

        determine_optimal_parallel(
          {timings, machine_count, machine_index},
          do_greedy_number_partitioning({timings, machine_count, machine_index})
        )

      [{_, last_duration, _} | _] when last_duration > max_duration ->
        IO.puts(:stderr, "other jobs duration: #{last_duration |> Float.round(1)}. trying again with #{machine_count + 1} groups...")

        determine_optimal_parallel(
          {timings, machine_count + 1, machine_index},
          do_greedy_number_partitioning({timings, machine_count + 1, machine_index})
        )

      _ ->
        IO.puts(:stderr, "optimal parallel found at #{machine_count} parallel jobs")
        {partitioned_tests, machine_index}
    end
  end

  defp respond({partitioned_tests, machine_index}) when is_integer(machine_index) do
    partitioned_tests
    |> Enum.find(fn {index, _, _} -> index == machine_index end)
    |> elem(2)
    |> Enum.each(fn {_, filename} -> IO.puts(filename) end)
  end

  defp respond({partitioned_tests, _}) do
    partitioned_tests
    |> Enum.map(&Tuple.to_list(&1))
    |> Enum.map(fn [index, duration, files] ->
      [
        index,
        duration |> Float.round(1),
        Enum.reduce(files, "", fn {duration, filename}, acc ->
          "#{duration} - #{filename}\n#{acc}"
        end)
      ]
    end)
    |> TableRex.quick_render!()
    |> IO.puts()
  end
end
