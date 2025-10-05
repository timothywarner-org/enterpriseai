# GitHub MCP Test Project

A Python project for testing GitHub tokens and creating AI agents that can interact with GitHub repositories via MCP (Model Context Protocol) server.

## 🎯 Project Overview

This project provides:
- **GitHub token validation** - Quick test to verify your GitHub token works
- **MCP server testing** - Test MCP server connection with GitHub integration
- **AI chat agent** - Azure AI agent that can chat about GitHub repositories
- **Safe for public repos** - All secrets managed through environment variables

## 📋 Prerequisites

- Python 3.8 or higher
- GitHub personal access token
- Azure AI Project credentials
- Node.js (for MCP server - `npx` command)

## 🚀 Quick Start

### 1. Clone or Download

```bash
cd "c:\Users\Charles Elwood\Documents\MCP Test Github Token"
```

### 2. Create Virtual Environment

```powershell
python -m venv venv
.\venv\Scripts\Activate.ps1
```

### 3. Install Dependencies

```bash
pip install -r requirements.txt
```

### 4. Configure Environment Variables

Copy the example environment file:

```bash
copy .env.example .env
```

Edit `.env` and add your credentials:

```env
# GitHub Configuration
GITHUB_PERSONAL_ACCESS_TOKEN=ghp_your_token_here

# Azure AI Project Configuration
AZURE_AI_PROJECT_CONNECTION_STRING=your_connection_string_here

# Optional: Model Configuration
MODEL_NAME=gpt-4o
```

### 5. Test Your Setup

**Step 1: Test GitHub Token**
```bash
python quick-github-test.py
```

**Step 2: Test MCP Chat (Optional)**
```bash
python test-mcp-github-chat.py
```

**Step 3: Run Advanced Agent**
```bash
python advanced-mcp-github-agent.py
```

## 📁 Project Structure

```
MCP Test Github Token/
├── .env.example              # Environment template (safe to commit)
├── .env                      # Your actual credentials (NEVER commit)
├── .gitignore               # Protects secrets from being committed
├── requirements.txt         # Python dependencies
├── README.md               # This file
├── quick-github-test.py    # Simple GitHub token validator
├── test-mcp-github-chat.py # MCP server connection test
└── advanced-mcp-github-agent.py  # Full-featured AI agent
```

## 🔑 Getting Your Credentials

### GitHub Personal Access Token

1. Go to https://github.com/settings/tokens
2. Click "Generate new token" → "Generate new token (classic)"
3. Give it a name (e.g., "MCP Test")
4. Select scopes:
   - `repo` (Full control of private repositories)
   - `read:user` (Read user profile data)
   - `read:org` (Read org and team membership)
5. Click "Generate token"
6. **Copy the token immediately** (you won't see it again!)
7. Add to your `.env` file

### Azure AI Project Connection String

**Option 1: From Azure Portal**
1. Go to https://portal.azure.com
2. Navigate to your Azure AI Project
3. Go to "Keys and Endpoint"
4. Copy the connection string

**Option 2: From Azure AI Studio**
1. Go to https://ai.azure.com
2. Select your project
3. Go to "Settings" → "Project properties"
4. Copy the connection string

## 📝 Script Descriptions

### `quick-github-test.py`
**Purpose:** Validate your GitHub token quickly  
**What it does:**
- Tests token authentication
- Displays user information
- Shows API rate limits
- Lists recent repositories

**When to use:** First step to verify your GitHub token works

### `test-mcp-github-chat.py`
**Purpose:** Test MCP server connection  
**What it does:**
- Initializes Azure AI client
- Configures MCP GitHub server
- Creates an AI agent
- Tests a simple conversation

**When to use:** Verify MCP integration is working

### `advanced-mcp-github-agent.py`
**Purpose:** Full-featured AI agent for GitHub  
**What it does:**
- Creates an intelligent GitHub assistant
- Supports multiple conversation modes (demo/interactive)
- Can search repos, read files, analyze code
- Handles complex queries about repositories

**When to use:** Main application for chatting about GitHub repos

## 🎓 Usage Examples

### Example 1: Validate Token
```bash
python quick-github-test.py
```

**Expected Output:**
```
✅ GitHub token is VALID!

📊 User Information:
   Username: octocat
   Name: The Octocat
   Public Repos: 8
   ...
```

### Example 2: Ask About Repositories
```bash
python advanced-mcp-github-agent.py
```

**Sample Conversation:**
```
Select mode:
1. Demo mode (automated questions)
2. Interactive mode (chat freely)

Enter choice: 2

👤 You: What are the top Python ML libraries?
🤖 Assistant: Based on GitHub data, the top Python ML libraries are:
1. tensorflow/tensorflow - ⭐ 185k stars
2. pytorch/pytorch - ⭐ 79k stars
...
```

## 🛡️ Security Best Practices

### ✅ DO:
- Keep `.env` in `.gitignore` (already configured)
- Use `.env.example` as a template (safe to commit)
- Rotate tokens periodically
- Use minimal required token scopes
- Review token permissions regularly

### ❌ DON'T:
- Commit `.env` file to git
- Share tokens in chat/email
- Use tokens with unnecessary permissions
- Hard-code credentials in scripts
- Push tokens to public repositories

### Checking Before Commit:
```bash
git status  # Verify .env is not listed
git diff    # Check no secrets in tracked files
```

## 🔧 Troubleshooting

### Problem: "GITHUB_PERSONAL_ACCESS_TOKEN not found"
**Solution:** 
1. Verify `.env` file exists (not `.env.example`)
2. Check token variable name matches exactly
3. Ensure no extra spaces around the `=` sign

### Problem: "401 Unauthorized" from GitHub
**Solution:**
1. Token may be expired - generate a new one
2. Check token has required scopes
3. Verify token copied correctly (no extra spaces)

### Problem: "Azure AI connection failed"
**Solution:**
1. Verify connection string is complete
2. Check Azure credentials are valid
3. Ensure Azure AI Project is deployed
4. Try `az login` to refresh credentials

### Problem: "Module not found"
**Solution:**
```bash
pip install -r requirements.txt
```

### Problem: "npx not found" (MCP server)
**Solution:**
Install Node.js from https://nodejs.org

## 🔄 Updating Dependencies

```bash
pip install --upgrade -r requirements.txt
```

## 📚 Additional Resources

- [GitHub API Documentation](https://docs.github.com/en/rest)
- [Azure AI Projects Documentation](https://learn.microsoft.com/en-us/azure/ai-services/)
- [MCP Protocol Specification](https://modelcontextprotocol.io/)
- [PyGithub Documentation](https://pygithub.readthedocs.io/)

## 🤝 Contributing

This is a personal test project, but feel free to:
- Report issues
- Suggest improvements
- Share your own examples

## 📄 License

This project is for educational and testing purposes.

## ⚠️ Important Notes

1. **Never commit your `.env` file** - it contains secrets!
2. **GitHub API rate limits apply** - authenticated requests get 5,000/hour
3. **Azure costs may apply** - monitor your usage
4. **MCP requires Node.js** - ensure `npx` is available

## 🎉 Success Checklist

- [ ] Python virtual environment created
- [ ] Dependencies installed
- [ ] `.env` file configured with credentials
- [ ] GitHub token validated with `quick-github-test.py`
- [ ] Azure AI connection tested
- [ ] Successfully ran at least one chat query
- [ ] `.env` confirmed in `.gitignore`

---

**Need Help?** Check the troubleshooting section or review the error messages carefully - they usually point to the issue!
