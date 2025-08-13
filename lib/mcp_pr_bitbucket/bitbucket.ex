defmodule MCPBitbucketPr.Bitbucket do
  @moduledoc false
  @max_diff 200_000

  defstruct [:base_url, :auth_mode, :token, :workspace, :project]

  def new(env \\ System.get_env()) do
    %__MODULE__{
      base_url: fetch!(env, "BITBUCKET_BASE_URL"),
      auth_mode: env["BITBUCKET_AUTH_MODE"] || "CLOUD_BEARER",
      token: fetch!(env, "BITBUCKET_TOKEN"),
      workspace: env["BITBUCKET_WORKSPACE"],
      project: env["BITBUCKET_PROJECT"]
    }
  end

  defp fetch!(env, key) do
    case env[key] do
      nil -> raise "#{key} not defined in environment"
      v -> v
    end
  end

  defp headers(%__MODULE__{auth_mode: mode, token: token})
       when mode in ["CLOUD_BEARER", "SERVER_BEARER"] do
    [
      {"authorization", "Bearer " <> token},
      {"content-type", "application/json"}
    ]
  end

  defp url(%__MODULE__{base_url: b}, path), do: b <> path

  defp req!(method, url, headers, body \\ nil) do
    opts =
      [method: method, url: url, headers: headers]
      |> maybe_body(body)

    resp = Req.request!(opts)
    ct = resp.headers |> Enum.into(%{}) |> Map.get("content-type", "")

    cond do
      is_binary(resp.body) and String.starts_with?(ct, "text/") ->
        resp.body

      String.contains?(ct, "application/json") ->
        resp.body

      true ->
        resp.body
    end
  end

  defp maybe_body(opts, nil), do: opts
  defp maybe_body(opts, body), do: Keyword.put(opts, :json, body)

  def create_pull_request(
        bb,
        repo,
        title,
        source_branch,
        dest_branch,
        description \\ nil,
        close? \\ false
      ) do
    case bb.auth_mode do
      "CLOUD_BEARER" ->
        workspace = bb.workspace || raise "BITBUCKET_WORKSPACE is required for Cloud"

        body = %{
          "title" => title,
          "source" => %{"branch" => %{"name" => source_branch}},
          "destination" => %{"branch" => %{"name" => dest_branch}},
          "description" => description || "",
          "close_source_branch" => close?
        }

        req!(:post, url(bb, "/repositories/#{workspace}/#{repo}/pullrequests"), headers(bb), body)

      "SERVER_BEARER" ->
        project = bb.project || raise "BITBUCKET_PROJECT is required for Server/DC"

        body = %{
          "title" => title,
          "description" => description || "",
          "fromRef" => %{"id" => "refs/heads/#{source_branch}"},
          "toRef" => %{"id" => "refs/heads/#{dest_branch}"},
          "closeSourceBranch" => close?
        }

        req!(
          :post,
          url(bb, "/projects/#{project}/repos/#{repo}/pull-requests"),
          headers(bb),
          body
        )

      other ->
        raise "Unsupported auth mode: #{other}"
    end
  end

  def get_pull_request(bb, repo, pr_id) do
    case bb.auth_mode do
      "CLOUD_BEARER" ->
        workspace = bb.workspace || raise "BITBUCKET_WORKSPACE is required for Cloud"

        req!(
          :get,
          url(bb, "/repositories/#{workspace}/#{repo}/pullrequests/#{pr_id}"),
          headers(bb)
        )

      "SERVER_BEARER" ->
        project = bb.project || raise "BITBUCKET_PROJECT is required for Server/DC"

        req!(
          :get,
          url(bb, "/projects/#{project}/repos/#{repo}/pull-requests/#{pr_id}"),
          headers(bb)
        )
    end
  end

  def get_diffstat(bb, repo, pr_id) do
    case bb.auth_mode do
      "CLOUD_BEARER" ->
        workspace = bb.workspace || raise "BITBUCKET_WORKSPACE is required for Cloud"

        req!(
          :get,
          url(
            bb,
            "/repositories/#{workspace}/#{repo}/pullrequests/#{pr_id}/diffstat?pagelen=1000"
          ),
          headers(bb)
        )

      "SERVER_BEARER" ->
        project = bb.project || raise "BITBUCKET_PROJECT is required for Server/DC"

        req!(
          :get,
          url(bb, "/projects/#{project}/repos/#{repo}/pull-requests/#{pr_id}/changes?limit=1000"),
          headers(bb)
        )
    end
  end

  def get_diff(bb, repo, pr_id) do
    raw =
      case bb.auth_mode do
        "CLOUD_BEARER" ->
          workspace = bb.workspace || raise "BITBUCKET_WORKSPACE is required for Cloud"

          req!(
            :get,
            url(bb, "/repositories/#{workspace}/#{repo}/pullrequests/#{pr_id}/diff"),
            headers(bb)
          )

        "SERVER_BEARER" ->
          project = bb.project || raise "BITBUCKET_PROJECT is required for Server/DC"

          req!(
            :get,
            url(bb, "/projects/#{project}/repos/#{repo}/pull-requests/#{pr_id}/diff"),
            headers(bb)
          )
      end

    diff = if is_binary(raw), do: raw, else: Jason.encode_to_iodata!(raw) |> IO.iodata_to_binary()

    if String.length(diff) > @max_diff do
      String.slice(diff, 0, @max_diff) <> "\n\n--- DIFF TRUNCATED ---"
    else
      diff
    end
  end

  def get_comments(bb, repo, pr_id) do
    case bb.auth_mode do
      "CLOUD_BEARER" ->
        workspace = bb.workspace || raise "BITBUCKET_WORKSPACE is required for Cloud"

        req!(
          :get,
          url(
            bb,
            "/repositories/#{workspace}/#{repo}/pullrequests/#{pr_id}/comments?pagelen=100"
          ),
          headers(bb)
        )

      "SERVER_BEARER" ->
        project = bb.project || raise "BITBUCKET_PROJECT is required for Server/DC"
        # activities include comments
        req!(
          :get,
          url(
            bb,
            "/projects/#{project}/repos/#{repo}/pull-requests/#{pr_id}/activities?limit=100"
          ),
          headers(bb)
        )
    end
  end

  def post_comment(bb, repo, pr_id, %{"text" => text} = c) do
    path = Map.get(c, "path")
    line = Map.get(c, "line")

    case bb.auth_mode do
      "CLOUD_BEARER" ->
        workspace = bb.workspace || raise "BITBUCKET_WORKSPACE is required for Cloud"

        body =
          if path && is_integer(line) do
            %{"content" => %{"raw" => text}, "inline" => %{"path" => path, "to" => line}}
          else
            %{"content" => %{"raw" => text}}
          end

        req!(
          :post,
          url(bb, "/repositories/#{workspace}/#{repo}/pullrequests/#{pr_id}/comments"),
          headers(bb),
          body
        )

      "SERVER_BEARER" ->
        project = bb.project || raise "BITBUCKET_PROJECT is required for Server/DC"
        # General comment; detailed inline varies between versions, keeping it simple
        body = %{"text" => text}

        req!(
          :post,
          url(bb, "/projects/#{project}/repos/#{repo}/pull-requests/#{pr_id}/comments"),
          headers(bb),
          body
        )
    end
  end
end
