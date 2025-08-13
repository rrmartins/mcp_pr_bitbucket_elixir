# MCP Bitbucket Elixir

A Model Context Protocol (MCP) server implementation in Elixir for Bitbucket integration. This tool provides AI assistants with the ability to interact with Bitbucket repositories, create pull requests, review code, and manage PR workflows.

## Features

- **Create Pull Requests**: Create new pull requests with customizable titles, descriptions, and branch configurations
- **Get PR Context**: Fetch comprehensive PR information including metadata, diff stats, file changes, and comments
- **Post Review Comments**: Add inline code comments and general review feedback to pull requests
- **MCP Protocol Support**: Full compatibility with MCP version 2024-11-05

## Tools Available

### `create_pull_request`
Creates a new pull request in Bitbucket.

**Parameters:**
- `repo` (required): Repository identifier
- `title` (required): Pull request title
- `source_branch` (required): Source branch name
- `destination_branch` (required): Destination branch name
- `description` (optional): Pull request description
- `close_source_branch` (optional): Whether to close source branch after merge

### `get_pull_request_context`
Retrieves comprehensive information about a pull request.

**Parameters:**
- `repo` (required): Repository identifier
- `pr_id` (required): Pull request ID

**Returns:**
- PR metadata
- File diff statistics
- Code diff (truncated for large changes)
- All comments and reviews

### `post_review_comments`
Posts review comments to a pull request.

**Parameters:**
- `repo` (required): Repository identifier
- `pr_id` (required): Pull request ID
- `comments` (required): Array of comment objects with `text`, optional `path`, and optional `line`

## Installation

### Prerequisites

- Elixir ~> 1.18
- Erlang/OTP 27

### Environment Setup

Create a `.env` file with your Bitbucket credentials:

```bash
BITBUCKET_USERNAME=your_username
BITBUCKET_APP_PASSWORD=your_app_password
```

### Build the Application

```bash
# Install dependencies
mix deps.get

# Build the escript
mix escript.build
```

This creates an executable `mcp_pr_bitbucket_elixir` file.

### Using as MCP Server

Run the server in MCP mode:

```bash
./mcp_pr_bitbucket_elixir
```

The server communicates via JSON-RPC over stdio, making it compatible with any MCP client.

## Development

### Dependencies

- `jason`: JSON encoding/decoding
- `req`: HTTP client for Bitbucket API calls
- `dotenvy`: Environment variable management

### Running Tests

```bash
mix test
```

## Configuration

The application uses environment variables for Bitbucket authentication:

- `BITBUCKET_USERNAME`: Your Bitbucket username
- `BITBUCKET_APP_PASSWORD`: Bitbucket app password (not your account password)

## Architecture

The project is structured as:

- `MCPBitbucketPr.Server`: Main MCP server handling JSON-RPC requests
- `MCPBitbucketPr.Bitbucket`: Bitbucket API client implementation
- `MCPBitbucketPr.JSONRPC`: JSON-RPC protocol utilities
- `MCPBitbucketPr.CLI`: Command-line interface entry point

