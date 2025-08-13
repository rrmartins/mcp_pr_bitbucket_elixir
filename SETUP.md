# MCP Bitbucket PR Integration for Cursor IDE

## Overview

This MCP (Model Context Protocol) server enables Cursor IDE to interact with Bitbucket repositories, specifically for Pull Request operations including creating PRs, fetching PR context, and posting review comments.

## Features

- **Create Pull Requests**: Create new PRs in Bitbucket repositories
- **Get PR Context**: Fetch PR metadata, diffstat, diff (truncated for large diffs), and comments
- **Post Review Comments**: Submit review comments (inline or general) to existing PRs
- **Multi-platform Support**: Works with both Bitbucket Cloud and Bitbucket Server/Data Center

## Prerequisites

- Elixir 1.18 or higher
- Mix build tool
- Cursor IDE
- Bitbucket account with appropriate permissions

## Installation & Setup

### 1. Build the Executable

```bash
# Navigate to the project directory
cd mcp_pr_bitbucket_elixir

# Clean and build the executable
mix clean && mix escript.build

# Copy to a permanent location
mkdir -p ~/.local/bin
cp ./mcp_pr_bitbucket_elixir ~/.local/bin/
chmod +x ~/.local/bin/mcp_pr_bitbucket_elixir
```

### 2. Configure Bitbucket Credentials

#### For Bitbucket Cloud:

1. Go to **Settings → App passwords** in your Bitbucket account
2. Create a new app password with permissions:
   - Repositories: Read/Write
   - Pull requests: Read/Write
3. Note down the generated password

#### For Bitbucket Server/Data Center:

1. Go to **Settings → Personal access tokens**
2. Create a token with permissions:
   - PROJECT_READ
   - REPO_READ
   - REPO_WRITE
3. Note down the generated token

### 3. Configure Cursor IDE

#### Locate the MCP Settings File

On macOS, the file is located at:
```
~/Library/Application Support/Cursor/User/globalStorage/rooveterinaryinc.claude-dev/settings/mcp_settings.json
```

#### Configuration for Bitbucket Cloud

Add this configuration to your `mcp_settings.json`:

```json
{
  "mcpServers": {
    "bitbucket-pr": {
      "command": "/Users/YOUR_USERNAME/.local/bin/mcp_pr_bitbucket_elixir",
      "args": [],
      "env": {
        "BITBUCKET_BASE_URL": "https://api.bitbucket.org/2.0",
        "BITBUCKET_AUTH_MODE": "CLOUD_BEARER",
        "BITBUCKET_TOKEN": "your_app_password_here",
        "BITBUCKET_WORKSPACE": "your_workspace_name"
      }
    }
  }
}
```

#### Configuration for Bitbucket Server/Data Center

```json
{
  "mcpServers": {
    "bitbucket-pr": {
      "command": "/Users/YOUR_USERNAME/.local/bin/mcp_pr_bitbucket_elixir",
      "args": [],
      "env": {
        "BITBUCKET_BASE_URL": "https://your-bitbucket-server.com/rest/api/1.0",
        "BITBUCKET_AUTH_MODE": "SERVER_BEARER",
        "BITBUCKET_TOKEN": "your_personal_access_token",
        "BITBUCKET_PROJECT": "your_project_key"
      }
    }
  }
}
```

**Important**: Replace `YOUR_USERNAME` with your actual username and fill in the appropriate values for your setup.

### 4. Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `BITBUCKET_BASE_URL` | Yes | Base URL for Bitbucket API |
| `BITBUCKET_AUTH_MODE` | Yes | Authentication mode: `CLOUD_BEARER` or `SERVER_BEARER` |
| `BITBUCKET_TOKEN` | Yes | App password (Cloud) or Personal Access Token (Server) |
| `BITBUCKET_WORKSPACE` | Cloud only | Workspace name for Bitbucket Cloud |
| `BITBUCKET_PROJECT` | Server only | Project key for Bitbucket Server/Data Center |

### 5. Restart Cursor

After saving the `mcp_settings.json` file, restart Cursor IDE to load the MCP server.

## Available Tools

Once configured, you'll have access to these tools in Cursor:

### 1. create_pull_request
Creates a new Pull Request in a Bitbucket repository.

**Parameters:**
- `repo` (string, required): Repository name
- `title` (string, required): PR title
- `source_branch` (string, required): Source branch name
- `destination_branch` (string, required): Destination branch name
- `description` (string, optional): PR description
- `close_source_branch` (boolean, optional): Whether to close source branch after merge

### 2. get_pull_request_context
Fetches comprehensive information about a Pull Request.

**Parameters:**
- `repo` (string, required): Repository name
- `pr_id` (number, required): Pull Request ID

**Returns:**
- PR metadata (title, description, author, status, etc.)
- File changes summary (diffstat)
- Code differences (diff, truncated if large)
- Existing comments

### 3. post_review_comments
Posts review comments to a Pull Request.

**Parameters:**
- `repo` (string, required): Repository name
- `pr_id` (number, required): Pull Request ID
- `comments` (array, required): Array of comment objects

**Comment Object Structure:**
- `text` (string, required): Comment content
- `path` (string, optional): File path for inline comments
- `line` (number, optional): Line number for inline comments

## Usage Examples

### Example 1: Get PR Context and Review
```
"Fetch the context for PR #123 in repository 'my-app' and provide a code review"
```

### Example 2: Create a New PR
```
"Create a pull request in repository 'my-app' from branch 'feature/new-login' to 'main' with title 'Add new login functionality'"
```

### Example 3: Post Review Comments
```
"Post review comments to PR #123 in repository 'my-app': suggest using const instead of let on line 15 of login.js"
```

## Troubleshooting

### Build Issues
- Ensure Elixir 1.18+ is installed: `elixir --version`
- Check dependencies: `mix deps.get`
- Clean build: `mix clean && mix escript.build`

### Authentication Issues
- Verify your token has the correct permissions
- Check that environment variables are correctly set in `mcp_settings.json`
- For Bitbucket Cloud, ensure you're using an App Password, not your account password
- For Bitbucket Server, ensure the base URL includes `/rest/api/1.0`

### MCP Server Issues
- Check that the executable path in `mcp_settings.json` is correct
- Ensure the executable has execute permissions: `chmod +x ~/.local/bin/mcp_pr_bitbucket_elixir`
- Restart Cursor after configuration changes
- Check Cursor's developer tools for error messages

### API Rate Limits
- Bitbucket Cloud: 60 requests per hour for App Passwords
- Bitbucket Server: Limits vary by server configuration
- Consider implementing request caching if hitting limits frequently

## Security Notes

- Never commit tokens or passwords to version control
- Use environment variables or secure configuration files for sensitive data
- Regularly rotate your access tokens
- Limit token permissions to only what's necessary

## Contributing

To contribute to this project:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Ensure all tests pass: `mix test`
5. Build and test the executable: `mix escript.build`
6. Submit a pull request

## License

This project is licensed under the MIT License. See LICENSE file for details.