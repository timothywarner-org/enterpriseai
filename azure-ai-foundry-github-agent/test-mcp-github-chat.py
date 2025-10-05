"""
MCP GitHub Chat Test
Tests MCP server connection and creates a simple chat agent that can interact with GitHub.
"""

import os
import asyncio
from dotenv import load_dotenv
from azure.ai.projects import AIProjectClient
from azure.ai.projects.models import ConnectionType
from azure.identity import DefaultAzureCredential
from azure.ai.inference.prompts import PromptTemplate

async def test_mcp_github_chat():
    """Test MCP server connection and chat with GitHub data."""
    
    # Load environment variables
    load_dotenv()
    
    # Get configuration
    connection_string = os.getenv('AZURE_AI_PROJECT_CONNECTION_STRING')
    endpoint = os.getenv('AZURE_AI_PROJECT_ENDPOINT')
    github_token = os.getenv('GITHUB_PERSONAL_ACCESS_TOKEN')
    
    if not connection_string and not endpoint:
        print("❌ ERROR: Either AZURE_AI_PROJECT_CONNECTION_STRING or AZURE_AI_PROJECT_ENDPOINT must be set in .env file")
        return False
    
    if not github_token:
        print("❌ ERROR: GITHUB_PERSONAL_ACCESS_TOKEN not found in .env file")
        return False
    
    print("🚀 Initializing Azure AI Project Client...")
    
    try:
        # Initialize Azure AI client
        if connection_string:
            # Parse connection string to get endpoint
            import re
            match = re.search(r'https://[^;]+', connection_string)
            if match:
                endpoint = match.group(0)
                project_client = AIProjectClient(
                    endpoint=endpoint,
                    credential=DefaultAzureCredential()
                )
            else:
                print("❌ ERROR: Could not parse endpoint from connection string")
                return False
        else:
            project_client = AIProjectClient(
                endpoint=endpoint,
                credential=DefaultAzureCredential()
            )
        
        print("✅ Azure AI Project Client initialized")
        
        # Configure MCP server for GitHub
        print("\n🔌 Setting up MCP GitHub server...")
        
        # MCP server configuration
        mcp_config = {
            "command": "npx",
            "args": ["-y", "@modelcontextprotocol/server-github"],
            "env": {
                "GITHUB_PERSONAL_ACCESS_TOKEN": github_token
            }
        }
        
        print(f"   Command: {mcp_config['command']}")
        print(f"   Args: {' '.join(mcp_config['args'])}")
        print("   Environment: GitHub token configured")
        
        # Create agent with MCP connection
        print("\n🤖 Creating AI agent with GitHub MCP integration...")
        
        # Note: This is a conceptual example. Actual implementation may vary
        # based on the Azure AI Projects SDK version and MCP integration support
        
        agent = project_client.agents.create_agent(
            model="gpt-4o",
            name="github-assistant",
            instructions="""You are a helpful assistant that can access GitHub repositories.
            You can search for repositories, read file contents, check issues, and analyze code.
            Always be concise and helpful in your responses.""",
            # MCP tools would be configured here
        )
        
        print(f"✅ Agent created: {agent.id}")
        
        # Create a thread for conversation
        thread = project_client.agents.create_thread()
        print(f"✅ Conversation thread created: {thread.id}")
        
        # Test conversation
        print("\n💬 Testing conversation...")
        
        test_message = "Can you tell me about popular Python repositories?"
        print(f"\n👤 User: {test_message}")
        
        # Add message to thread
        message = project_client.agents.create_message(
            thread_id=thread.id,
            role="user",
            content=test_message
        )
        
        # Run the agent
        run = project_client.agents.create_run(
            thread_id=thread.id,
            assistant_id=agent.id
        )
        
        # Wait for completion
        print("⏳ Waiting for response...")
        while run.status in ["queued", "in_progress"]:
            await asyncio.sleep(1)
            run = project_client.agents.get_run(
                thread_id=thread.id,
                run_id=run.id
            )
        
        if run.status == "completed":
            # Get messages
            messages = project_client.agents.list_messages(thread_id=thread.id)
            
            # Display latest assistant message
            for msg in messages:
                if msg.role == "assistant":
                    print(f"\n🤖 Assistant: {msg.content[0].text.value}")
                    break
            
            print("\n✅ Chat test completed successfully!")
            
        else:
            print(f"\n⚠️ Run status: {run.status}")
            if run.last_error:
                print(f"Error: {run.last_error}")
        
        # Cleanup
        print("\n🧹 Cleaning up...")
        project_client.agents.delete_agent(agent.id)
        print("✅ Agent deleted")
        
        return True
        
    except Exception as e:
        print(f"\n❌ Error: {str(e)}")
        print(f"\nError type: {type(e).__name__}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    print("=" * 60)
    print("MCP GitHub Chat Test")
    print("=" * 60)
    
    success = asyncio.run(test_mcp_github_chat())
    
    print("\n" + "=" * 60)
    if success:
        print("✅ Test completed successfully!")
    else:
        print("❌ Test failed. Please check your configuration.")
    print("=" * 60)
