defmodule MCPBitbucketPr.BitbucketTest do
  use ExUnit.Case, async: true

  alias MCPBitbucketPr.Bitbucket

  describe "new/1" do
    test "creates Bitbucket struct with required environment variables" do
      env = %{
        "BITBUCKET_BASE_URL" => "https://api.bitbucket.org/2.0",
        "BITBUCKET_TOKEN" => "test_token",
        "BITBUCKET_WORKSPACE" => "test_workspace"
      }

      bitbucket = Bitbucket.new(env)

      assert bitbucket.base_url == "https://api.bitbucket.org/2.0"
      assert bitbucket.auth_mode == "CLOUD_BASIC"
      assert bitbucket.token == "test_token"
      assert bitbucket.workspace == "test_workspace"
    end

    test "uses CLOUD_BEARER when specified" do
      env = %{
        "BITBUCKET_BASE_URL" => "https://api.bitbucket.org/2.0",
        "BITBUCKET_AUTH_MODE" => "CLOUD_BEARER",
        "BITBUCKET_TOKEN" => "test_token"
      }

      bitbucket = Bitbucket.new(env)
      assert bitbucket.auth_mode == "CLOUD_BEARER"
    end

    test "uses BITBUCKET_APP_PASSWORD when BITBUCKET_TOKEN is not present" do
      env = %{
        "BITBUCKET_BASE_URL" => "https://api.bitbucket.org/2.0",
        "BITBUCKET_APP_PASSWORD" => "app_password"
      }

      bitbucket = Bitbucket.new(env)
      assert bitbucket.token == "app_password"
    end

    test "raises error when required BITBUCKET_BASE_URL is missing" do
      env = %{"BITBUCKET_TOKEN" => "test_token"}

      assert_raise RuntimeError, "BITBUCKET_BASE_URL not defined in environment", fn ->
        Bitbucket.new(env)
      end
    end

    test "raises error when both BITBUCKET_TOKEN and BITBUCKET_APP_PASSWORD are missing" do
      env = %{"BITBUCKET_BASE_URL" => "https://api.bitbucket.org/2.0"}

      assert_raise RuntimeError, "BITBUCKET_APP_PASSWORD not defined in environment", fn ->
        Bitbucket.new(env)
      end
    end
  end

  # Note: Testing private functions requires different approach
  # We focus on testing public interface and behavior
end