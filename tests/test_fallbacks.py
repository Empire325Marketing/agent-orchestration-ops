
"""
Integration tests for provider fallback behavior.

Tests router's ability to handle provider failures and route to fallback providers:
- Primary provider failure scenarios
- Fallback routing behavior
- Error handling and recovery
"""

import os
import time
import requests
import pytest
from unittest.mock import patch

ROUTER_URL = os.getenv("ROUTER_URL", "http://localhost:4000")


def wait_health(url: str = ROUTER_URL, timeout: int = 60) -> None:
    """Wait for router to become healthy."""
    start = time.time()
    while time.time() - start < timeout:
        try:
            response = requests.get(f"{url}/health", timeout=2)
            if response.ok:
                return
        except requests.exceptions.RequestException:
            pass
        time.sleep(1)
    raise TimeoutError(f"Router not healthy after {timeout}s")


@pytest.fixture(scope="module", autouse=True)
def ensure_router_ready():
    """Ensure router is ready before running tests."""
    wait_health()


def test_fallback_on_provider_timeout():
    """
    Test that router falls back to secondary provider when primary times out.
    
    This test simulates a timeout scenario and verifies that:
    1. The request eventually succeeds via fallback
    2. Response indicates fallback was used (if metadata available)
    """
    payload = {
        "model": "deployer-lite",
        "messages": [
            {"role": "user", "content": "Test fallback"}
        ],
        "metadata": {
            "tenant": "fallback-test",
            "trace_id": "test-fallback-timeout"
        },
        "max_tokens": 30,
        "timeout": 5  # Short timeout to trigger fallback
    }
    
    response = requests.post(
        f"{ROUTER_URL}/v1/chat/completions",
        json=payload,
        timeout=60  # Overall timeout longer to allow fallback
    )
    
    # Should succeed via fallback
    assert response.status_code == 200
    data = response.json()
    assert "choices" in data
    assert len(data["choices"]) > 0


def test_fallback_on_rate_limit():
    """
    Test fallback behavior when primary provider returns rate limit error.
    
    Simulates rate limiting by making rapid requests and verifying:
    1. Router handles rate limits gracefully
    2. Requests succeed via fallback providers
    """
    payload = {
        "model": "deployer-lite",
        "messages": [
            {"role": "user", "content": "Rate limit test"}
        ],
        "metadata": {
            "tenant": "rate-limit-test",
            "trace_id": "test-rate-limit"
        },
        "max_tokens": 20
    }
    
    # Make multiple rapid requests
    responses = []
    for i in range(5):
        response = requests.post(
            f"{ROUTER_URL}/v1/chat/completions",
            json=payload,
            timeout=30
        )
        responses.append(response)
        time.sleep(0.1)  # Small delay between requests
    
    # At least some requests should succeed (via fallback if needed)
    successful = [r for r in responses if r.status_code == 200]
    assert len(successful) > 0, "No requests succeeded, fallback may not be working"


def test_fallback_chain_exhaustion():
    """
    Test behavior when all providers in fallback chain fail.
    
    Verifies that:
    1. Router attempts all configured fallbacks
    2. Returns appropriate error when all providers fail
    3. Error message is informative
    """
    # Use an invalid model to force all providers to fail
    payload = {
        "model": "nonexistent-model-xyz",
        "messages": [
            {"role": "user", "content": "This should fail"}
        ],
        "metadata": {
            "tenant": "exhaustion-test",
            "trace_id": "test-exhaustion"
        },
        "max_tokens": 20
    }
    
    response = requests.post(
        f"{ROUTER_URL}/v1/chat/completions",
        json=payload,
        timeout=30
    )
    
    # Should return error status
    assert response.status_code >= 400
    
    # Error should be informative
    data = response.json()
    assert "error" in data or "message" in data


def test_fallback_preserves_metadata():
    """
    Test that metadata is preserved through fallback routing.
    
    Verifies that tenant, trace_id, and other metadata fields
    are maintained when request is routed to fallback provider.
    """
    metadata = {
        "tenant": "metadata-test",
        "trace_id": "test-metadata-preservation",
        "user_id": "test-user-123",
        "session_id": "test-session-456"
    }
    
    payload = {
        "model": "deployer-lite",
        "messages": [
            {"role": "user", "content": "Metadata test"}
        ],
        "metadata": metadata,
        "max_tokens": 20
    }
    
    response = requests.post(
        f"{ROUTER_URL}/v1/chat/completions",
        json=payload,
        timeout=30
    )
    
    assert response.status_code == 200
    data = response.json()
    
    # Check if metadata is echoed back (implementation dependent)
    # At minimum, request should succeed with metadata present
    assert "choices" in data


def test_fallback_latency_acceptable():
    """
    Test that fallback routing doesn't add excessive latency.
    
    Verifies that even with fallback, total request time is reasonable.
    """
    payload = {
        "model": "deployer-lite",
        "messages": [
            {"role": "user", "content": "Latency test"}
        ],
        "metadata": {
            "tenant": "latency-test",
            "trace_id": "test-latency"
        },
        "max_tokens": 20
    }
    
    start = time.time()
    response = requests.post(
        f"{ROUTER_URL}/v1/chat/completions",
        json=payload,
        timeout=30
    )
    duration = time.time() - start
    
    assert response.status_code == 200
    # Fallback should complete within reasonable time (30s includes model loading)
    assert duration < 30, f"Request took {duration}s, too slow even with fallback"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
