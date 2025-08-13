defmodule MCPBitbucketPr.CLI do
  @moduledoc false
  alias MCPBitbucketPr.Server

  # Reads JSON-RPC from STDIN; messages may come multi-line.
  # Strategy: buffer until we can decode a valid JSON.
  def main(args \\ []) do
    case args do
      ["--version"] -> print_version()
      ["-v"] -> print_version()
      ["--help"] -> print_help()
      ["-h"] -> print_help()
      [] -> start_server()
      _ -> 
        IO.puts("Unknown arguments: #{Enum.join(args, " ")}")
        print_help()
        System.halt(1)
    end
  end

  defp print_version do
    IO.puts("mcp-bitbucket-elixir 0.1.0")
    System.halt(0)
  end

  defp print_help do
    IO.puts("""
    MCP Bitbucket Elixir - Model Context Protocol server for Bitbucket integration

    Usage:
      mcp_pr_bitbucket_elixir [OPTIONS]

    Options:
      --version, -v    Show version information
      --help, -h       Show this help message

    When run without arguments, starts the MCP server and listens for JSON-RPC messages on stdin.

    Environment Variables:
      BITBUCKET_USERNAME      Your Bitbucket username
      BITBUCKET_APP_PASSWORD  Your Bitbucket app password

    Available Tools:
      - create_pull_request      Create a new pull request
      - get_pull_request_context Get PR metadata, diff, and comments
      - post_review_comments     Post review comments to a PR
    """)
    System.halt(0)
  end

  defp start_server do
    # load .env if it exists
    _ = Dotenvy.source(["~/.env", ".env"])

    loop("")
  end

  defp loop(buffer) do
    case IO.read(:stdio, :line) do
      :eof ->
        :ok

      {:error, _} ->
        :ok

      data ->
        buf = buffer <> (data || "")

        case try_decode(buf) do
          {:ok, msg, rest} ->
            handle_message(msg)
            loop(rest)

          :more ->
            loop(buf)
        end
    end
  end

  defp try_decode(buf) do
    # try to decode; if it fails, wait for more data
    case Jason.decode(buf) do
      {:ok, msg} ->
        {:ok, msg, ""}

      {:error, _} ->
        # try to detect boundary by double newline (messages often come one per line)
        case split_first_json(buf) do
          {:ok, json, rest} ->
            case Jason.decode(json) do
              {:ok, msg} -> {:ok, msg, rest}
              _ -> :more
            end

          :more ->
            :more
        end
    end
  end

  # Simple heuristic: find the first line that seems to close a JSON (brace balancing)
  defp split_first_json(buf) do
    lines = String.split(buf, "\n", trim: false)

    {json_lines, rest_lines, _depth} =
      Enum.reduce_while(Enum.with_index(lines), {[], [], 0}, fn {line, idx},
                                                                {acc, _rest, depth} ->
        {depth2, done?} = update_depth(depth, line)

        acc2 = acc ++ [line]

        cond do
          done? and depth2 == 0 ->
            json = Enum.join(acc2, "\n")
            rest = Enum.join(Enum.slice(lines, (idx + 1)..-1), "\n")
            {:halt, {json, rest, depth2}}

          true ->
            {:cont, {acc2, [], depth2}}
        end
      end)

    if json_lines == [] do
      :more
    else
      {:ok, json_lines, rest_lines}
    end
  end

  defp update_depth(depth, line) do
    # ignore braces inside strings in a simplified way
    open = count(line, "{")
    close = count(line, "}")
    d = max(depth + open - close, 0)
    done? = String.contains?(line, "}")
    {d, done?}
  end

  defp count(s, char) do
    s
    |> String.graphemes()
    |> Enum.count(&(&1 == char))
  end

  defp handle_message(%{"method" => _} = msg) do
    resp = Server.handle(msg)
    IO.write(Jason.encode!(resp))
    IO.write("\n")
    :ok
  end

  defp handle_message(_other) do
    # ignore messages without "method"
    :ok
  end
end
