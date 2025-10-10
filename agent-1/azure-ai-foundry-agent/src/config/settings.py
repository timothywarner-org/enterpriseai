# settings.py

import os

class Config:
    # GPT-4o model settings
    GPT4O_MODEL_NAME = os.getenv('GPT4O_MODEL_NAME', 'gpt-4o')
    GPT4O_API_KEY = os.getenv('GPT4O_API_KEY')

    # Azure Search settings
    AZURE_SEARCH_ENDPOINT = os.getenv('AZURE_SEARCH_ENDPOINT')
    AZURE_SEARCH_API_KEY = os.getenv('AZURE_SEARCH_API_KEY')
    AZURE_SEARCH_INDEX_NAME = os.getenv('AZURE_SEARCH_INDEX_NAME')

    # Cosmos DB settings
    COSMOSDB_URI = os.getenv('COSMOSDB_URI')
    COSMOSDB_KEY = os.getenv('COSMOSDB_KEY')
    COSMOSDB_DATABASE_NAME = os.getenv('COSMOSDB_DATABASE_NAME')
    COSMOSDB_CONTAINER_NAME = os.getenv('COSMOSDB_CONTAINER_NAME')

    # GitHub MCP tool settings
    GITHUB_API_URL = os.getenv('GITHUB_API_URL')
    GITHUB_API_TOKEN = os.getenv('GITHUB_API_TOKEN')

    @staticmethod
    def validate():
        required_vars = [
            'GPT4O_API_KEY',
            'AZURE_SEARCH_ENDPOINT',
            'AZURE_SEARCH_API_KEY',
            'COSMOSDB_URI',
            'COSMOSDB_KEY',
            'GITHUB_API_URL',
            'GITHUB_API_TOKEN'
        ]
        for var in required_vars:
            if not os.getenv(var):
                raise ValueError(f'Missing required environment variable: {var}')