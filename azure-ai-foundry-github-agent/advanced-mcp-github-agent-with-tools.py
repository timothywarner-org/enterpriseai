"""
Advanced MCP GitHub Agent with GitHub Tools
A full-featured AI agent that can interact with GitHub repositories using custom GitHub tools.
This version integrates PyGithub library as custom functions for the agent.
"""

import os
import asyncio
from dotenv import load_dotenv
from azure.ai.projects import AIProjectClient
from azure.identity import DefaultAzureCredential
from typing import Optional
from github import Github, Auth
import json

class GitHubTools:
    """GitHub tools wrapper for the AI agent."""
    
    def __init__(self, github_token: str):
        """Initialize GitHub client."""
        auth = Auth.Token(github_token)
        self.github = Github(auth=auth)
    
    def search_repositories(self, query: str, max_results: int = 5) -> str:
        """
        Search for GitHub repositories.
        
        Args:
            query: Search query (e.g., 'python machine learning', 'language:python stars:>1000')
            max_results: Maximum number of results to return (default: 5)
            
        Returns:
            JSON string with repository information
        """
        try:
            repos = self.github.search_repositories(query=query, sort='stars', order='desc')
            results = []
            
            for i, repo in enumerate(repos[:max_results], 1):
                results.append({
                    "rank": i,
                    "name": repo.full_name,
                    "description": repo.description or "No description",
                    "stars": repo.stargazers_count,
                    "forks": repo.forks_count,
                    "language": repo.language or "Not specified",
                    "url": repo.html_url,
                    "topics": repo.get_topics()[:5] if hasattr(repo, 'get_topics') else []
                })
            
            return json.dumps({"repositories": results, "total_found": repos.totalCount}, indent=2)
        except Exception as e:
            return json.dumps({"error": str(e)})
    
    def get_repository_info(self, repo_full_name: str) -> str:
        """
        Get detailed information about a specific repository.
        
        Args:
            repo_full_name: Full repository name (e.g., 'microsoft/vscode')
            
        Returns:
            JSON string with detailed repository information
        """
        try:
            repo = self.github.get_repo(repo_full_name)
            
            info = {
                "name": repo.full_name,
                "description": repo.description,
                "stars": repo.stargazers_count,
                "forks": repo.forks_count,
                "watchers": repo.watchers_count,
                "open_issues": repo.open_issues_count,
                "language": repo.language,
                "license": repo.license.name if repo.license else "No license",
                "created_at": repo.created_at.isoformat(),
                "updated_at": repo.updated_at.isoformat(),
                "topics": repo.get_topics()[:10],
                "url": repo.html_url,
                "default_branch": repo.default_branch,
                "size_kb": repo.size,
                "has_wiki": repo.has_wiki,
                "has_issues": repo.has_issues,
            }
            
            return json.dumps(info, indent=2)
        except Exception as e:
            return json.dumps({"error": str(e)})
    
    def get_trending_languages(self) -> str:
        """
        Get information about trending programming languages on GitHub.
        
        Returns:
            JSON string with popular languages
        """
        try:
            # Search for highly starred repos in different languages
            languages = ['Python', 'JavaScript', 'TypeScript', 'Java', 'Go', 'Rust', 'C++']
            results = []
            
            for lang in languages:
                query = f"language:{lang} stars:>1000"
                repos = self.github.search_repositories(query=query, sort='stars', order='desc')
                
                if repos.totalCount > 0:
                    top_repo = repos[0]
                    results.append({
                        "language": lang,
                        "total_repos": repos.totalCount,
                        "top_repo": top_repo.full_name,
                        "top_repo_stars": top_repo.stargazers_count
                    })
            
            return json.dumps({"trending_languages": results}, indent=2)
        except Exception as e:
            return json.dumps({"error": str(e)})
    
    def get_my_repositories(self, max_results: int = 10) -> str:
        """
        Get the authenticated user's repositories.
        
        Args:
            max_results: Maximum number of repositories to return (default: 10)
            
        Returns:
            JSON string with user's repository information
        """
        try:
            user = self.github.get_user()
            repos = user.get_repos(sort='updated', direction='desc')
            results = []
            
            for i, repo in enumerate(repos[:max_results], 1):
                results.append({
                    "rank": i,
                    "name": repo.full_name,
                    "description": repo.description or "No description",
                    "stars": repo.stargazers_count,
                    "forks": repo.forks_count,
                    "language": repo.language or "Not specified",
                    "url": repo.html_url,
                    "private": repo.private,
                    "updated_at": repo.updated_at.isoformat(),
                    "topics": repo.get_topics()[:5] if hasattr(repo, 'get_topics') else []
                })
            
            return json.dumps({
                "username": user.login,
                "total_repos": user.public_repos,
                "repositories": results
            }, indent=2)
        except Exception as e:
            return json.dumps({"error": str(e)})

class GitHubMCPAgent:
    """AI Agent with GitHub tools integration."""
    
    def __init__(self):
        """Initialize the agent."""
        load_dotenv()
        self.endpoint = os.getenv('AZURE_AI_PROJECT_ENDPOINT')
        self.github_token = os.getenv('GITHUB_PERSONAL_ACCESS_TOKEN')
        self.model_name = os.getenv('MODEL_NAME', 'gpt-4o')
        
        self.project_client: Optional[AIProjectClient] = None
        self.agent = None
        self.thread = None
        self.github_tools = None
        
    async def initialize(self):
        """Initialize Azure AI client and create agent with GitHub tools."""
        
        if not self.endpoint:
            raise ValueError("AZURE_AI_PROJECT_ENDPOINT must be set in .env file")
        
        if not self.github_token:
            raise ValueError("GITHUB_PERSONAL_ACCESS_TOKEN not found")
        
        print("🚀 Initializing GitHub MCP Agent with Tools...")
        print("🔐 Authenticating with Azure...")
        
        # Initialize Azure AI client
        self.project_client = AIProjectClient(
            endpoint=self.endpoint,
            credential=DefaultAzureCredential()
        )
        
        print("✅ Azure AI Project Client initialized")
        
        # Initialize GitHub tools
        print("🔧 Setting up GitHub tools...")
        self.github_tools = GitHubTools(self.github_token)
        print("✅ GitHub tools configured")
        
        # Create agent with GitHub tools
        print(f"🤖 Creating agent with model: {self.model_name}")
        
        # Define function tools for the agent
        tools = [
            {
                "type": "function",
                "function": {
                    "name": "search_repositories",
                    "description": "Search for GitHub repositories by query. Can search by keywords, language, stars, and more.",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "query": {
                                "type": "string",
                                "description": "Search query. Examples: 'python machine learning', 'language:rust stars:>1000', 'topic:ai'"
                            },
                            "max_results": {
                                "type": "integer",
                                "description": "Maximum number of results to return (1-10)",
                                "default": 5
                            }
                        },
                        "required": ["query"]
                    }
                }
            },
            {
                "type": "function",
                "function": {
                    "name": "get_repository_info",
                    "description": "Get detailed information about a specific GitHub repository by its full name (owner/repo).",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "repo_full_name": {
                                "type": "string",
                                "description": "Full repository name in format 'owner/repository'. Example: 'microsoft/vscode'"
                            }
                        },
                        "required": ["repo_full_name"]
                    }
                }
            },
            {
                "type": "function",
                "function": {
                    "name": "get_trending_languages",
                    "description": "Get information about trending programming languages on GitHub based on repository counts and popularity.",
                    "parameters": {
                        "type": "object",
                        "properties": {}
                    }
                }
            },
            {
                "type": "function",
                "function": {
                    "name": "get_my_repositories",
                    "description": "Get the authenticated user's own GitHub repositories with details. Use this when asked about 'my repos', 'my repositories', or 'my GitHub projects'.",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "max_results": {
                                "type": "integer",
                                "description": "Maximum number of repositories to return (1-20)",
                                "default": 10
                            }
                        }
                    }
                }
            }
        ]
        
        self.agent = self.project_client.agents.create_agent(
            model=self.model_name,
            name="github-mcp-agent-with-tools",
            instructions="""You are an expert GitHub assistant with direct access to GitHub data through specialized tools.

Your capabilities:
- **search_repositories**: Search for repositories by any criteria (language, topic, stars, etc.)
- **get_repository_info**: Get detailed information about specific repositories
- **get_trending_languages**: Analyze trending programming languages on GitHub

When asked about repositories:
1. Use search_repositories to find relevant repos
2. Use get_repository_info for detailed analysis of specific repos
3. Always cite specific repository names, stars, and other metrics
4. Provide context about why repositories are relevant
5. Suggest related repositories when appropriate

Be concise, accurate, and always back up your statements with data from the tools.
Format repository names as owner/repo and include links when mentioning them.""",
            tools=tools
        )
        
        print(f"✅ Agent created: {self.agent.id}")
        print("✅ GitHub tools integrated")
        
        # Create conversation thread
        self.thread = self.project_client.agents.threads.create()
        print(f"✅ Thread created: {self.thread.id}")
        
    def handle_tool_call(self, tool_call):
        """Handle tool calls from the agent."""
        function_name = tool_call.function.name
        arguments = json.loads(tool_call.function.arguments)
        
        print(f"🔧 Calling tool: {function_name}")
        print(f"   Arguments: {arguments}")
        
        # Execute the appropriate function
        if function_name == "search_repositories":
            result = self.github_tools.search_repositories(**arguments)
        elif function_name == "get_repository_info":
            result = self.github_tools.get_repository_info(**arguments)
        elif function_name == "get_trending_languages":
            result = self.github_tools.get_trending_languages()
        elif function_name == "get_my_repositories":
            result = self.github_tools.get_my_repositories(**arguments)
        else:
            result = json.dumps({"error": f"Unknown function: {function_name}"})
        
        return result
        
    async def chat(self, user_message: str) -> str:
        """Send a message and get response."""
        
        if not self.agent or not self.thread:
            raise RuntimeError("Agent not initialized. Call initialize() first.")
        
        print(f"\n👤 User: {user_message}")
        
        # Add user message
        self.project_client.agents.messages.create(
            thread_id=self.thread.id,
            role="user",
            content=user_message
        )
        
        # Run the agent
        run = self.project_client.agents.runs.create(
            thread_id=self.thread.id,
            agent_id=self.agent.id
        )
        
        # Wait for completion and handle tool calls
        print("⏳ Processing...")
        while run.status in ["queued", "in_progress", "requires_action"]:
            await asyncio.sleep(1)
            run = self.project_client.agents.runs.get(
                thread_id=self.thread.id,
                run_id=run.id
            )
            
            # Handle required actions (tool calls)
            if run.status == "requires_action":
                print("🔧 Agent is using GitHub tools...")
                
                tool_calls = run.required_action.submit_tool_outputs.tool_calls
                tool_outputs = []
                
                for tool_call in tool_calls:
                    output = self.handle_tool_call(tool_call)
                    tool_outputs.append({
                        "tool_call_id": tool_call.id,
                        "output": output
                    })
                
                # Submit tool outputs
                run = self.project_client.agents.runs.submit_tool_outputs(
                    thread_id=self.thread.id,
                    run_id=run.id,
                    tool_outputs=tool_outputs
                )
        
        # Get response
        if run.status == "completed":
            messages = self.project_client.agents.messages.list(
                thread_id=self.thread.id
            )
            
            # Get latest assistant message
            for msg in messages:
                if msg.role == "assistant":
                    response = msg.content[0].text.value
                    print(f"\n🤖 Assistant: {response}")
                    return response
            
        elif run.status == "failed":
            error_msg = f"Run failed: {run.last_error}"
            print(f"\n❌ {error_msg}")
            return error_msg
        
        return "No response received"
    
    async def cleanup(self):
        """Clean up resources."""
        if self.agent and self.project_client:
            print("\n🧹 Cleaning up...")
            self.project_client.agents.delete_agent(self.agent.id)
            print("✅ Agent deleted")

async def run_demo():
    """Run a demo conversation."""
    
    agent = GitHubMCPAgent()
    
    try:
        # Initialize
        await agent.initialize()
        
        print("\n" + "=" * 60)
        print("🎯 Starting Demo Conversation")
        print("=" * 60)
        
        # Demo questions that will use GitHub tools
        demo_questions = [
            "What are the top 3 most popular Python machine learning repositories?",
            "Tell me about the microsoft/vscode repository",
            "What programming languages are trending on GitHub?",
        ]
        
        for i, question in enumerate(demo_questions, 1):
            print(f"\n{'='*60}")
            print(f"Question {i}/{len(demo_questions)}")
            print(f"{'='*60}")
            
            await agent.chat(question)
            
            # Pause between questions
            if i < len(demo_questions):
                await asyncio.sleep(2)
        
        print("\n" + "=" * 60)
        print("✅ Demo completed!")
        print("=" * 60)
        
    except Exception as e:
        print(f"\n❌ Error: {str(e)}")
        import traceback
        traceback.print_exc()
        
    finally:
        await agent.cleanup()

async def run_interactive():
    """Run interactive chat mode."""
    
    agent = GitHubMCPAgent()
    
    try:
        # Initialize
        await agent.initialize()
        
        print("\n" + "=" * 60)
        print("💬 Interactive Chat Mode with GitHub Tools")
        print("=" * 60)
        print("Type 'exit' or 'quit' to end the conversation")
        print("\nExample questions:")
        print("- What are the most popular Rust repositories?")
        print("- Tell me about the Azure/azure-sdk-for-python repo")
        print("- Find repositories about artificial intelligence")
        print("=" * 60)
        
        while True:
            try:
                user_input = input("\n👤 You: ").strip()
                
                if user_input.lower() in ['exit', 'quit', 'bye']:
                    print("\n👋 Goodbye!")
                    break
                
                if not user_input:
                    continue
                
                await agent.chat(user_input)
                
            except KeyboardInterrupt:
                print("\n\n👋 Goodbye!")
                break
                
    except Exception as e:
        print(f"\n❌ Error: {str(e)}")
        import traceback
        traceback.print_exc()
        
    finally:
        await agent.cleanup()

if __name__ == "__main__":
    print("=" * 60)
    print("Advanced MCP GitHub Agent with GitHub Tools")
    print("=" * 60)
    print("\nSelect mode:")
    print("1. Demo mode (automated questions)")
    print("2. Interactive mode (chat freely)")
    
    choice = input("\nEnter choice (1 or 2): ").strip()
    
    if choice == "1":
        asyncio.run(run_demo())
    elif choice == "2":
        asyncio.run(run_interactive())
    else:
        print("Invalid choice. Exiting.")
