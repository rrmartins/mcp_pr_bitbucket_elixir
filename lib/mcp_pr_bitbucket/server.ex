defmodule MCPBitbucketPr.Server do
  @moduledoc false
  alias MCPBitbucketPr.JSONRPC
  alias MCPBitbucketPr.Bitbucket

  # recent MCP version
  @protocol_version "2024-11-05"
  @server_name "mcp-bitbucket-elixir"
  @server_version "0.1.0"

  def handle(%{"method" => "initialize", "id" => id}) do
    JSONRPC.ok(id, %{
      "protocolVersion" => @protocol_version,
      "capabilities" => %{
        "tools" => %{}
      },
      "serverInfo" => %{
        "name" => @server_name,
        "version" => @server_version
      }
    })
  end

  def handle(%{"method" => "tools/list", "id" => id}) do
    tools = [
      %{
        "name" => "create_pull_request",
        "description" => "Creates a Pull Request in Bitbucket",
        "inputSchema" => %{
          "type" => "object",
          "properties" => %{
            "repo" => %{"type" => "string"},
            "title" => %{"type" => "string"},
            "source_branch" => %{"type" => "string"},
            "destination_branch" => %{"type" => "string"},
            "description" => %{"type" => "string"},
            "close_source_branch" => %{"type" => "boolean"}
          },
          "required" => ["repo", "title", "source_branch", "destination_branch"]
        }
      },
      %{
        "name" => "get_pull_request_context",
        "description" => "Fetches PR metadata, diffstat, diff (truncated) and comments",
        "inputSchema" => %{
          "type" => "object",
          "properties" => %{
            "repo" => %{"type" => "string"},
            "pr_id" => %{"type" => "number"}
          },
          "required" => ["repo", "pr_id"]
        }
      },
      %{
        "name" => "post_review_comments",
        "description" => "Posts review comments (inline or general) to the PR",
        "inputSchema" => %{
          "type" => "object",
          "properties" => %{
            "repo" => %{"type" => "string"},
            "pr_id" => %{"type" => "number"},
            "comments" => %{
              "type" => "array",
              "items" => %{
                "type" => "object",
                "properties" => %{
                  "text" => %{"type" => "string"},
                  "path" => %{"type" => "string"},
                  "line" => %{"type" => "number"}
                },
                "required" => ["text"]
              }
            }
          },
          "required" => ["repo", "pr_id", "comments"]
        }
      }
    ]

    JSONRPC.ok(id, %{"tools" => tools})
  end

  def handle(%{
        "method" => "tools/call",
        "id" => id,
        "params" => %{"name" => name, "arguments" => args}
      }) do
    bb = Bitbucket.new()

    try do
      result =
        case name do
          "create_pull_request" ->
            pr =
              Bitbucket.create_pull_request(
                bb,
                fetch!(args, "repo"),
                fetch!(args, "title"),
                fetch!(args, "source_branch"),
                fetch!(args, "destination_branch"),
                Map.get(args, "description"),
                Map.get(args, "close_source_branch", false)
              )

            textify(pr)

          "get_pull_request_context" ->
            repo = fetch!(args, "repo")
            pr_id = fetch!(args, "pr_id")

            meta = Bitbucket.get_pull_request(bb, repo, pr_id)
            files = Bitbucket.get_diffstat(bb, repo, pr_id)
            diff = Bitbucket.get_diff(bb, repo, pr_id)
            comments = Bitbucket.get_comments(bb, repo, pr_id)

            textify(%{"meta" => meta, "files" => files, "diff" => diff, "comments" => comments})

          "post_review_comments" ->
            repo = fetch!(args, "repo")
            pr_id = fetch!(args, "pr_id")
            comments = Map.get(args, "comments") || []

            results =
              Enum.map(comments, fn c ->
                Bitbucket.post_comment(bb, repo, pr_id, c)
              end)

            textify(results)

          other ->
            raise "Unsupported tool: #{other}"
        end

      JSONRPC.ok(id, %{"content" => [%{"type" => "text", "text" => result}]})
    rescue
      e ->
        JSONRPC.error(id, -32000, Exception.message(e))
    end
  end

  def handle(%{"id" => id}) do
    JSONRPC.error(id, -32601, "Method not implemented")
  end

  defp fetch!(map, key), do: Map.fetch!(map, key)

  defp textify(map) when is_map(map), do: Jason.encode!(map)
  defp textify(list) when is_list(list), do: Jason.encode!(list)
  defp textify(bin) when is_binary(bin), do: bin
end
