class AzureSearch:
    def __init__(self, search_service_name, index_name, api_key):
        self.search_service_name = search_service_name
        self.index_name = index_name
        self.api_key = api_key
        self.endpoint = f"https://{search_service_name}.search.windows.net"
        self.headers = {
            "Content-Type": "application/json",
            "api-key": api_key
        }

    def search_documents(self, search_text, top=10):
        search_url = f"{self.endpoint}/indexes/{self.index_name}/docs/search?api-version=2021-04-30-Preview"
        search_body = {
            "search": search_text,
            "top": top
        }
        response = requests.post(search_url, headers=self.headers, json=search_body)
        response.raise_for_status()
        return response.json().get('value', [])

    def get_document_by_id(self, document_id):
        search_url = f"{self.endpoint}/indexes/{self.index_name}/docs/{document_id}?api-version=2021-04-30-Preview"
        response = requests.get(search_url, headers=self.headers)
        response.raise_for_status()
        return response.json()