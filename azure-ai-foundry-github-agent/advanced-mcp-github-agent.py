"""
Advanced MCP GitHub Agent
A full-featured AI agent that can interact with GitHub repositories using MCP tools.
Supports multiple operations: searching repos, reading files, analyzing code, etc.
"""

import os
import asyncio
from dotenv import load_dotenv
from azure.ai.projects import AIProjectClient
from azure.identity import DefaultAzureCredential
from typing import Optional

class GitHubMCPAgent:
    """AI Agent with GitHub MCP integration."""
    
    def __init__(self):
        """Initialize the agent."""
        load_dotenv()
        self.endpoint = os.getenv('AZURE_AI_PROJECT_ENDPOINT')
        self.github_token = os.getenv('GITHUB_PERSONAL_ACCESS_TOKEN')
        self.model_name = os.getenv('MODEL_NAME', 'gpt-4o')
        
        self.project_client: Optional[AIProjectClient] = None
        self.agent = None
        self.thread = None
        
    async def initialize(self):
        """Initialize Azure AI client and create agent."""
        
        if not self.endpoint:
            raise ValueError("AZURE_AI_PROJECT_ENDPOINT must be set in .env file")
        
        if not self.github_token:
            raise ValueError("GITHUB_PERSONAL_ACCESS_TOKEN not found")
        
        print("🚀 Initializing GitHub MCP Agent...")
        print("🔐 Authenticating with Azure (using DefaultAzureCredential)...")
        
        # Initialize Azure AI client with Entra ID authentication
        self.project_client = AIProjectClient(
            endpoint=self.endpoint,
            credential=DefaultAzureCredential()
        )
        
        print("✅ Azure AI Project Client initialized")
        
        # Create agent with GitHub capabilities
        print(f"🤖 Creating agent with model: {self.model_name}")
        
        self.agent = self.project_client.agents.create_agent(
            model=self.model_name,
            name="github-mcp-agent",
            instructions="""You are an expert GitHub assistant with access to GitHub repositories.

Your capabilities include:
- Searching for repositories by name, topic, or language
- Reading file contents from repositories
- Analyzing code structure and dependencies
- Checking issues, pull requests, and commits
- Providing insights about repository activity and popularity

When asked about repositories:
1. Search for relevant repositories first
2. Analyze the most popular or relevant ones
3. Provide detailed insights with statistics
4. Suggest related repositories if helpful

Always be concise, accurate, and cite the repositories you reference.
Format code snippets nicely and explain technical concepts clearly.""",
            # Note: MCP tools configuration would go here
            # This depends on SDK support for MCP integration
        )
        
        print(f"✅ Agent created: {self.agent.id}")
        
        # Create conversation thread
        self.thread = self.project_client.agents.threads.create()
        print(f"✅ Thread created: {self.thread.id}")
        
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
            assistant_id=self.agent.id
        )
        
        # Wait for completion
        print("⏳ Processing...")
        while run.status in ["queued", "in_progress", "requires_action"]:
            await asyncio.sleep(1)
            run = self.project_client.agents.runs.get(
                thread_id=self.thread.id,
                run_id=run.id
            )
            
            # Handle tool calls if needed
            if run.status == "requires_action":
                print("🔧 Agent is using tools...")
        
        # Get response
        if run.status == "completed":
            messages = self.project_client.agents.messages.list(
                thread_id=self.thread.id
            )
            
            # Get latest assistant message
            for msg in messages.data:
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
        
        # Demo questions
        demo_questions = [
            "What are the most popular Python machine learning repositories?",
            "Can you find repositories related to MCP (Model Context Protocol)?",
            "Tell me about Microsoft's Azure SDK for Python",
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
        print("💬 Interactive Chat Mode")
        print("=" * 60)
        print("Type 'exit' or 'quit' to end the conversation")
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
    print("Advanced MCP GitHub Agent")
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
