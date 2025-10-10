class MCPGitHub:
    def __init__(self, github_token):
        self.github_token = github_token
        self.base_url = "https://api.github.com"

    def call_tool(self, endpoint, method='GET', data=None):
        headers = {
            'Authorization': f'token {self.github_token}',
            'Accept': 'application/vnd.github.v3+json'
        }
        url = f"{self.base_url}/{endpoint}"

        if method == 'GET':
            response = requests.get(url, headers=headers)
        elif method == 'POST':
            response = requests.post(url, headers=headers, json=data)
        elif method == 'PUT':
            response = requests.put(url, headers=headers, json=data)
        elif method == 'DELETE':
            response = requests.delete(url, headers=headers)
        else:
            raise ValueError("Invalid HTTP method")

        if response.status_code not in range(200, 300):
            raise Exception(f"GitHub API error: {response.status_code} - {response.text}")

        return response.json()