class CosmosDBMemory:
    def __init__(self, connection_string):
        self.connection_string = connection_string
        self.client = self._initialize_cosmos_client()
        self.database_name = "AIFoundryDB"
        self.container_name = "MemoryContainer"
        self.container = self._get_container()

    def _initialize_cosmos_client(self):
        from azure.cosmos import CosmosClient
        return CosmosClient.from_connection_string(self.connection_string)

    def _get_container(self):
        database = self.client.get_database_client(self.database_name)
        return database.get_container_client(self.container_name)

    def save_memory(self, user_id, memory_data):
        item = {
            "id": user_id,
            "memory": memory_data
        }
        self.container.upsert_item(item)

    def retrieve_memory(self, user_id):
        try:
            item = self.container.read_item(item=user_id, partition_key=user_id)
            return item.get("memory", None)
        except Exception as e:
            print(f"Error retrieving memory for user {user_id}: {str(e)}")
            return None