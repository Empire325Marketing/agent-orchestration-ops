
"""
Integration smoke tests for router health and basic functionality.

Tests basic router operations including:
- Health endpoint availability
- Simple chat completion requests
- Response format validation
"""

import os
import time
import requests
import pytest

ROUTER_URL = os.getenv("ROUTER_URL", "http://localhost:4000")
TIMEOUT = int(os.getenv("HEALTH_TIMEOUT", "60"))


def wait_health(url: str = ROUTER_URL, timeout: int = TIMEOUT) -> None:
    """
    Wait for router to become healthy.
    
    Args:
        url: Base URL of the router service
        timeout: Maximum seconds to wait for health
        
    Raises:
        TimeoutError: If router doesn't become healthy within timeout
    """
    start = time.time()
    while time.time() - start < timeout:
        try:
            response = requests.get(f"{url}/health", timeout=2)
            if response.ok:
                print(f"Router healthy after {time.time() - start:.1f}s")
                return
        except requests.exceptions.RequestException:
            pass
        time.sleep(1)
    
    raise TimeoutError(f"Router not healthy after {timeout}s")


def test_health_endpoint():
    """Test that the health endpoint responds correctly."""
    wait_health()
    
    response = requests.get(f"{ROUTER_URL}/health", timeout=5)
    assert response.status_code == 200
    
    data = response.json()
    assert "status" in data or response.ok


def test_health_and_chat():
    """Test basic chat completion through the router."""
    wait_health()
    
    payload = {
        "model": "deployer-lite",
        "messages": [
            {"role": "user", "content": "Say 'primarch ok' and nothing else."}
        ],
        "metadata": {
            "tenant": "ci",
            "trace_id": "test-smoke-1"
        },
        "max_tokens": 50,
        "temperature": 0.1
    }
    
    response = requests.post(
        f"{ROUTER_URL}/v1/chat/completions",
        json=payload,
        timeout=30
    )
    
    assert response.status_code == 200, f"Request failed: {response.text}"
    
    data = response.json()
    assert "choices" in data
    assert len(data["choices"]) > 0
    
    message = data["choices"][0]["message"]
    assert "content" in message
    
    content = message["content"].lower()
    assert "primarch" in content or "ok" in content, \
        f"Expected 'primarch ok' in response, got: {message['content']}"


def test_router_model_list():
    """Test that the router can list available models."""
    wait_health()
    
    response = requests.get(f"{ROUTER_URL}/v1/models", timeout=5)
    assert response.status_code == 200
    
    data = response.json()
    assert "data" in data or "models" in data


def test_chat_with_metadata():
    """Test that metadata is properly handled in requests."""
    wait_health()
    
    payload = {
        "model": "deployer-lite",
        "messages": [
            {"role": "user", "content": "Hello"}
        ],
        "metadata": {
            "tenant": "test-tenant",
            "trace_id": "test-trace-123",
            "user_id": "test-user"
        },
        "max_tokens": 20
    }
    
    response = requests.post(
        f"{ROUTER_URL}/v1/chat/completions",
        json=payload,
        timeout=30
    )
    
    assert response.status_code == 200
    data = response.json()
    assert "choices" in data


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
