defmodule MCPBitbucketPr.JSONRPCTest do
  use ExUnit.Case, async: true

  alias MCPBitbucketPr.JSONRPC

  describe "ok/2" do
    test "creates successful JSON-RPC response" do
      result = JSONRPC.ok("test-id", %{"data" => "test"})

      assert result == %{
        "jsonrpc" => "2.0",
        "id" => "test-id",
        "result" => %{"data" => "test"}
      }
    end

    test "handles nil result" do
      result = JSONRPC.ok("test-id", nil)

      assert result == %{
        "jsonrpc" => "2.0",
        "id" => "test-id",
        "result" => nil
      }
    end

    test "handles complex nested data" do
      complex_data = %{
        "tools" => [
          %{"name" => "tool1", "schema" => %{"type" => "object"}},
          %{"name" => "tool2", "schema" => %{"type" => "string"}}
        ],
        "count" => 2
      }

      result = JSONRPC.ok("test-id", complex_data)

      assert result["result"] == complex_data
      assert result["id"] == "test-id"
      assert result["jsonrpc"] == "2.0"
    end
  end

  describe "error/3" do
    test "creates error JSON-RPC response" do
      result = JSONRPC.error("test-id", -32000, "Test error message")

      assert result == %{
        "jsonrpc" => "2.0",
        "id" => "test-id",
        "error" => %{
          "code" => -32000,
          "message" => "Test error message"
        }
      }
    end

    test "handles different error codes" do
      result = JSONRPC.error("test-id", -32601, "Method not found")

      assert result["error"]["code"] == -32601
      assert result["error"]["message"] == "Method not found"
    end

    test "handles nil id" do
      result = JSONRPC.error(nil, -32600, "Invalid Request")

      assert result["id"] == nil
      assert result["error"]["code"] == -32600
      assert result["error"]["message"] == "Invalid Request"
    end

    test "handles empty error message" do
      result = JSONRPC.error("test-id", -32000, "")

      assert result["error"]["message"] == ""
      assert result["error"]["code"] == -32000
    end
  end

  describe "JSON-RPC specification compliance" do
    test "ok response includes required fields" do
      result = JSONRPC.ok("123", %{})

      # Must have jsonrpc version
      assert Map.has_key?(result, "jsonrpc")
      assert result["jsonrpc"] == "2.0"
      
      # Must have id
      assert Map.has_key?(result, "id")
      
      # Must have result
      assert Map.has_key?(result, "result")
      
      # Must not have error
      refute Map.has_key?(result, "error")
    end

    test "error response includes required fields" do
      result = JSONRPC.error("123", -32000, "Error")

      # Must have jsonrpc version
      assert Map.has_key?(result, "jsonrpc")
      assert result["jsonrpc"] == "2.0"
      
      # Must have id
      assert Map.has_key?(result, "id")
      
      # Must have error
      assert Map.has_key?(result, "error")
      
      # Error must have code and message
      assert Map.has_key?(result["error"], "code")
      assert Map.has_key?(result["error"], "message")
      
      # Must not have result
      refute Map.has_key?(result, "result")
    end
  end
end