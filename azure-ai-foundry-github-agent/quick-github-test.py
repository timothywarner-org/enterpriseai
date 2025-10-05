"""
Quick GitHub Token Test
Tests your GitHub personal access token and displays basic information.
"""

import os
from dotenv import load_dotenv
from github import Github, GithubException

def test_github_token():
    """Test GitHub token and display user information."""
    
    # Load environment variables
    load_dotenv()
    token = os.getenv('GITHUB_PERSONAL_ACCESS_TOKEN')
    
    if not token:
        print("❌ ERROR: GITHUB_PERSONAL_ACCESS_TOKEN not found in .env file")
        print("\nPlease:")
        print("1. Copy .env.example to .env")
        print("2. Add your GitHub token to the .env file")
        return False
    
    print("🔍 Testing GitHub token...")
    
    try:
        # Initialize GitHub client
        from github import Auth
        auth = Auth.Token(token)
        g = Github(auth=auth)
        
        # Get authenticated user
        user = g.get_user()
        
        print("\n✅ GitHub token is VALID!")
        print(f"\n📊 User Information:")
        print(f"   Username: {user.login}")
        print(f"   Name: {user.name}")
        print(f"   Email: {user.email}")
        print(f"   Public Repos: {user.public_repos}")
        print(f"   Followers: {user.followers}")
        print(f"   Following: {user.following}")
        
        # Check rate limit
        try:
            rate_limit = g.get_rate_limit()
            core = rate_limit.core
            search = rate_limit.search
            print(f"\n📈 API Rate Limit:")
            print(f"   Core: {core.remaining}/{core.limit}")
            print(f"   Search: {search.remaining}/{search.limit}")
        except Exception as rate_error:
            print(f"\n📈 API Rate Limit: (Info unavailable - {str(rate_error)})")
        
        # List a few repositories
        print(f"\n📁 Recent Repositories:")
        repos = user.get_repos(sort='updated', direction='desc')
        for i, repo in enumerate(repos[:5], 1):
            print(f"   {i}. {repo.full_name} - ⭐ {repo.stargazers_count}")
        
        return True
        
    except GithubException as e:
        print(f"\n❌ GitHub API Error: {e.status}")
        print(f"   Message: {e.data.get('message', 'Unknown error')}")
        if e.status == 401:
            print("\n💡 Your token appears to be invalid or expired.")
            print("   Please generate a new token at: https://github.com/settings/tokens")
        return False
        
    except Exception as e:
        print(f"\n❌ Unexpected Error: {str(e)}")
        return False

if __name__ == "__main__":
    print("=" * 60)
    print("GitHub Token Validation Test")
    print("=" * 60)
    
    success = test_github_token()
    
    print("\n" + "=" * 60)
    if success:
        print("✅ Test completed successfully!")
    else:
        print("❌ Test failed. Please check your configuration.")
    print("=" * 60)
