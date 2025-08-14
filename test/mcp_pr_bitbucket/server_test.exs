defmodule MCPBitbucketPr.ServerTest do
  use ExUnit.Case, async: true

  alias MCPBitbucketPr.Server

  describe "handle/1 - initialize" do
    test "returns proper initialization response" do
      request = %{"method" => "initialize", "id" => "test-id"}

      response = Server.handle(request)

      assert response["id"] == "test-id"
      assert response["result"]["protocolVersion"] == "2024-11-05"
      assert response["result"]["serverInfo"]["name"] == "mcp-bitbucket-elixir"
      assert response["result"]["serverInfo"]["version"] == "0.1.0"
      assert Map.has_key?(response["result"]["capabilities"], "tools")
    end
  end

  describe "handle/1 - tools/list" do
    test "returns list of available tools" do
      request = %{"method" => "tools/list", "id" => "test-id"}

      response = Server.handle(request)

      assert response["id"] == "test-id"
      assert is_list(response["result"]["tools"])
      
      tools = response["result"]["tools"]
      tool_names = Enum.map(tools, & &1["name"])
      
      assert "create_pull_request" in tool_names
      assert "get_pull_request_context" in tool_names
      assert "post_review_comments" in tool_names
    end

    test "create_pull_request tool has correct schema" do
      request = %{"method" => "tools/list", "id" => "test-id"}
      response = Server.handle(request)
      
      tools = response["result"]["tools"]
      create_pr_tool = Enum.find(tools, &(&1["name"] == "create_pull_request"))
      
      assert create_pr_tool["description"] == "Creates a Pull Request in Bitbucket"
      
      schema = create_pr_tool["inputSchema"]
      required = schema["required"]
      properties = schema["properties"]
      
      assert "repo" in required
      assert "title" in required
      assert "source_branch" in required
      assert "destination_branch" in required
      
      assert Map.has_key?(properties, "repo")
      assert Map.has_key?(properties, "title")
      assert Map.has_key?(properties, "description")
      assert Map.has_key?(properties, "close_source_branch")
    end
  end

  describe "handle/1 - notifications/initialized" do
    test "returns nil for initialized notification" do
      request = %{"method" => "notifications/initialized"}

      response = Server.handle(request)

      assert response == nil
    end
  end

  describe "handle/1 - unknown method" do
    test "returns method not implemented error for unknown method with id" do
      request = %{"method" => "unknown_method", "id" => "test-id"}

      response = Server.handle(request)

      assert response["id"] == "test-id"
      assert response["error"]["code"] == -32601
      assert response["error"]["message"] == "Method not implemented"
    end

    test "returns method not implemented error for request with id but no method" do
      request = %{"id" => "test-id", "params" => %{}}

      response = Server.handle(request)

      assert response["id"] == "test-id"
      assert response["error"]["code"] == -32601
      assert response["error"]["message"] == "Method not implemented"
    end
  end

  describe "handle/1 - tools/call validation" do
    test "validates required arguments for create_pull_request" do
      # Mock the environment to avoid real API calls
      System.put_env([
        {"BITBUCKET_BASE_URL", "https://api.bitbucket.org/2.0"},
        {"BITBUCKET_TOKEN", "test_token"},
        {"BITBUCKET_WORKSPACE", "test_workspace"}
      ])

      request = %{
        "method" => "tools/call",
        "id" => "test-id",
        "params" => %{
          "name" => "create_pull_request",
          "arguments" => %{
            "repo" => "test/repo",
            "title" => "Test PR"
            # Missing required source_branch and destination_branch
          }
        }
      }

      response = Server.handle(request)

      assert response["id"] == "test-id"
      assert response["error"]["code"] == -32000
      assert String.contains?(response["error"]["message"], "source_branch")

      # Clean up
      System.delete_env("BITBUCKET_BASE_URL")
      System.delete_env("BITBUCKET_TOKEN")
      System.delete_env("BITBUCKET_WORKSPACE")
    end

    test "handles unsupported tool name" do
      # Mock the environment to avoid real API calls
      System.put_env([
        {"BITBUCKET_BASE_URL", "https://api.bitbucket.org/2.0"},
        {"BITBUCKET_TOKEN", "test_token"},
        {"BITBUCKET_WORKSPACE", "test_workspace"}
      ])

      request = %{
        "method" => "tools/call",
        "id" => "test-id",
        "params" => %{
          "name" => "unsupported_tool",
          "arguments" => %{}
        }
      }

      response = Server.handle(request)

      assert response["id"] == "test-id"
      assert response["error"]["code"] == -32000
      assert String.contains?(response["error"]["message"], "Unsupported tool")

      # Clean up
      System.delete_env("BITBUCKET_BASE_URL")
      System.delete_env("BITBUCKET_TOKEN")
      System.delete_env("BITBUCKET_WORKSPACE")
    end
  end
end