# File: /azure-ai-foundry-agent/azure-ai-foundry-agent/src/main.py

import logging
from agent import Agent
from config.settings import load_settings

def main():
    # Load application settings
    settings = load_settings()

    # Set up logging
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger(__name__)

    logger.info("Starting Azure AI Foundry Agent...")

    # Initialize the agent
    agent = Agent(settings)

    # Run the agent
    agent.run()

if __name__ == "__main__":
    main()