# RAG 2.0 Production Readiness Gates

**Document Version:** 1.0  
**Last Updated:** 2025-09-30  
**Gate Type:** Quality & Performance  
**Owner:** RAG Engineering Team  
**Approver:** Tech Lead & Product Owner  

## Executive Summary

This document defines the acceptance criteria, measurement procedures, and go/no-go decision framework for promoting the RAG 2.0 system to production. The system must demonstrate consistent performance across three critical dimensions before production deployment is authorized.

### Critical Success Metrics
| Metric | Target | Measurement Method | Gate Status |
|--------|--------|-------------------|-------------|
| **Retrieval Recall@10** | ≥ 0.90 | Automated evaluation on golden dataset | 🔴 PENDING |
| **Answer Faithfulness** | ≥ 0.95 | RAGAS + manual verification | 🔴 PENDING |
| **p95 Retrieval Latency** | ≤ 150ms | Load testing + monitoring | 🔴 PENDING |

---

## Gate 1: Retrieval Quality (R@10 ≥ 0.90)

### Objective
Demonstrate that the hybrid retrieval system (BM25 + vector + reranker) achieves a minimum recall@10 of 0.90 across diverse query types and document categories.

### Measurement Procedure

#### 1. Golden Dataset Requirements
```yaml
golden_dataset_spec:
  size: 1000  # minimum evaluation queries
  composition:
    factual_queries: 300      # "What is X?", "Define Y"
    procedural_queries: 250   # "How to do X?", "Steps for Y"
    comparative_queries: 200  # "Compare X and Y", "X vs Y"
    analytical_queries: 150   # "Why does X?", "What causes Y?"
    code_queries: 100        # "Function that does X", "Debug Y error"
  
  document_types:
    technical_docs: 40%   # API docs, specifications, manuals
    research_papers: 25%  # Academic papers, whitepapers
    code_repos: 20%      # Source code, GitHub repositories  
    forums_qa: 10%       # Stack Overflow, forums, Q&A
    news_articles: 5%    # Recent news, blog posts

  difficulty_distribution:
    easy: 30%    # Single-hop, direct answers
    medium: 50%  # Multi-step reasoning, synthesis
    hard: 20%    # Complex multi-hop, domain expertise
```

#### 2. Evaluation Script
```python
#!/usr/bin/env python3
"""
RAG Retrieval Quality Evaluation Script
Usage: python3 evaluate_retrieval.py --dataset golden_set.jsonl --output results.json
"""

import json
import numpy as np
from typing import List, Dict, Tuple
import time
from dataclasses import dataclass

@dataclass
class EvaluationResult:
    query_id: str
    query_text: str
    retrieved_docs: List[str]
    relevant_docs: List[str]
    recall_at_k: Dict[int, float]
    precision_at_k: Dict[int, float]
    retrieval_time_ms: float

def evaluate_retrieval_quality(dataset_path: str, rag_system) -> Dict:
    """
    Comprehensive retrieval quality evaluation
    """
    with open(dataset_path, 'r') as f:
        test_queries = [json.loads(line) for line in f]
    
    results = []
    total_time_ms = 0
    
    for query_data in test_queries:
        query = query_data['query']
        relevant_docs = set(query_data['relevant_documents'])
        
        # Measure retrieval time
        start_time = time.time()
        retrieved_docs = rag_system.retrieve(query, top_k=20)
        retrieval_time = (time.time() - start_time) * 1000
        total_time_ms += retrieval_time
        
        # Calculate metrics
        retrieved_ids = [doc['id'] for doc in retrieved_docs]
        
        recall_at_k = {}
        precision_at_k = {}
        
        for k in [1, 5, 10, 20]:
            top_k_retrieved = set(retrieved_ids[:k])
            
            # Recall@K = |relevant ∩ retrieved| / |relevant|
            recall_at_k[k] = len(relevant_docs & top_k_retrieved) / len(relevant_docs)
            
            # Precision@K = |relevant ∩ retrieved| / |retrieved|
            precision_at_k[k] = len(relevant_docs & top_k_retrieved) / k if k > 0 else 0
        
        results.append(EvaluationResult(
            query_id=query_data['id'],
            query_text=query,
            retrieved_docs=retrieved_ids,
            relevant_docs=list(relevant_docs),
            recall_at_k=recall_at_k,
            precision_at_k=precision_at_k,
            retrieval_time_ms=retrieval_time
        ))
    
    # Calculate aggregate metrics
    aggregate_metrics = calculate_aggregate_metrics(results)
    
    # Performance metrics
    performance_metrics = {
        "avg_retrieval_time_ms": total_time_ms / len(test_queries),
        "p95_retrieval_time_ms": np.percentile([r.retrieval_time_ms for r in results], 95),
        "p99_retrieval_time_ms": np.percentile([r.retrieval_time_ms for r in results], 99),
        "max_retrieval_time_ms": max(r.retrieval_time_ms for r in results)
    }
    
    return {
        "aggregate_metrics": aggregate_metrics,
        "performance_metrics": performance_metrics,
        "individual_results": [r.__dict__ for r in results],
        "evaluation_summary": {
            "total_queries": len(test_queries),
            "gate_status": "PASS" if aggregate_metrics["recall_at_10"] >= 0.90 else "FAIL"
        }
    }

def calculate_aggregate_metrics(results: List[EvaluationResult]) -> Dict:
    """Calculate aggregate metrics across all queries"""
    recall_10_scores = [r.recall_at_k[10] for r in results]
    precision_5_scores = [r.precision_at_k[5] for r in results]
    
    return {
        "recall_at_10": np.mean(recall_10_scores),
        "recall_at_10_std": np.std(recall_10_scores),
        "recall_at_10_min": np.min(recall_10_scores),
        "precision_at_5": np.mean(precision_5_scores),
        "precision_at_5_std": np.std(precision_5_scores),
        "queries_above_threshold": sum(1 for score in recall_10_scores if score >= 0.90),
        "pass_rate": sum(1 for score in recall_10_scores if score >= 0.90) / len(recall_10_scores)
    }
```

#### 3. Acceptance Criteria
- **Primary:** Average Recall@10 ≥ 0.90 across all queries
- **Secondary:** 
  - At least 85% of individual queries achieve Recall@10 ≥ 0.80
  - No query category performs below Recall@10 = 0.75
  - Standard deviation of Recall@10 scores ≤ 0.15
- **Performance:** p95 retrieval time ≤ 150ms during evaluation

#### 4. Verification Steps
```bash
# 1. Run automated evaluation
python3 evaluate_retrieval.py \
  --dataset /data/golden_dataset_v1.jsonl \
  --output /tmp/retrieval_evaluation_results.json \
  --config /config/rag_production.yaml

# 2. Generate detailed report
python3 generate_evaluation_report.py \
  --results /tmp/retrieval_evaluation_results.json \
  --output /reports/retrieval_gate_report.html

# 3. Validate results meet thresholds
python3 validate_retrieval_gate.py \
  --results /tmp/retrieval_evaluation_results.json \
  --thresholds /config/gate_thresholds.yaml
```

---

## Gate 2: Answer Faithfulness (≥ 0.95)

### Objective
Ensure that generated answers are faithful to the retrieved source material with minimal hallucination or factual errors.

### Measurement Procedure

#### 1. RAGAS Faithfulness Evaluation
```python
#!/usr/bin/env python3
"""
Answer Faithfulness Evaluation using RAGAS
"""

from ragas import evaluate
from ragas.metrics import faithfulness, answer_relevancy, context_relevancy
from datasets import Dataset
import pandas as pd

def evaluate_answer_faithfulness(test_dataset_path: str, rag_system) -> Dict:
    """
    Evaluate answer faithfulness using RAGAS framework
    """
    # Load test dataset
    with open(test_dataset_path, 'r') as f:
        test_data = [json.loads(line) for line in f]
    
    # Generate answers using RAG system
    evaluation_data = []
    
    for item in test_data:
        query = item['question']
        ground_truth = item.get('ground_truth', '')
        
        # Get RAG system response
        rag_response = rag_system.answer_query(query)
        
        evaluation_data.append({
            'question': query,
            'answer': rag_response['answer'],
            'contexts': rag_response['retrieved_contexts'],
            'ground_truths': [ground_truth] if ground_truth else []
        })
    
    # Convert to RAGAS dataset format
    dataset = Dataset.from_pandas(pd.DataFrame(evaluation_data))
    
    # Run RAGAS evaluation
    result = evaluate(
        dataset,
        metrics=[faithfulness, answer_relevancy, context_relevancy]
    )
    
    return {
        "faithfulness_score": result['faithfulness'],
        "answer_relevancy_score": result['answer_relevancy'], 
        "context_relevancy_score": result['context_relevancy'],
        "individual_scores": result.to_pandas().to_dict('records'),
        "gate_status": "PASS" if result['faithfulness'] >= 0.95 else "FAIL"
    }
```

#### 2. Manual Verification Protocol
```yaml
manual_verification:
  sample_size: 100  # Random sample from evaluation dataset
  reviewers: 2      # Independent reviewers per sample
  review_criteria:
    factual_accuracy: "Are all facts in the answer supported by sources?"
    completeness: "Does the answer address all aspects of the question?"
    attribution: "Can claims be traced back to specific source passages?"
    hallucination: "Are there any unsupported claims or fabricated information?"
  
  scoring_rubric:
    excellent: 1.0    # Perfect faithfulness, no issues
    good: 0.9        # Minor attribution issues
    acceptable: 0.8   # Some unsupported claims
    poor: 0.6        # Significant hallucination
    unacceptable: 0.0 # Mostly hallucinated

  inter_rater_reliability: "> 0.8"  # Cohen's kappa
```

#### 3. Automated Faithfulness Checks
```python
class AutomatedFaithfulnessChecker:
    """
    Automated checks for answer faithfulness
    """
    
    def __init__(self):
        self.fact_checker = load_fact_checking_model()
        self.entailment_model = load_entailment_model()
    
    def check_faithfulness(self, answer: str, contexts: List[str]) -> Dict:
        """
        Automated faithfulness verification
        """
        results = {
            "entailment_score": self.check_entailment(answer, contexts),
            "fact_consistency": self.check_fact_consistency(answer, contexts),
            "attribution_coverage": self.check_attribution_coverage(answer, contexts),
            "hallucination_score": self.detect_hallucinations(answer, contexts)
        }
        
        # Calculate composite faithfulness score
        weights = {"entailment": 0.4, "fact_consistency": 0.3, 
                  "attribution": 0.2, "hallucination": 0.1}
        
        composite_score = sum(
            results[key] * weights[key.split('_')[0]] 
            for key in results.keys()
        )
        
        results["composite_faithfulness"] = composite_score
        return results

    def check_entailment(self, answer: str, contexts: List[str]) -> float:
        """Check if answer is entailed by contexts"""
        entailment_scores = []
        
        for context in contexts:
            score = self.entailment_model.predict(context, answer)
            entailment_scores.append(score)
        
        return max(entailment_scores) if entailment_scores else 0.0
```

#### 4. Acceptance Criteria
- **Primary:** RAGAS faithfulness score ≥ 0.95
- **Secondary:**
  - Manual verification average score ≥ 0.93
  - Inter-rater reliability (Cohen's kappa) ≥ 0.80
  - Less than 5% of answers flagged for significant hallucination
  - Automated faithfulness checks pass 95% of samples

---

## Gate 3: Performance (p95 Latency ≤ 150ms)

### Objective
Demonstrate that the RAG system consistently delivers retrieval results within 150ms at the 95th percentile under production load conditions.

### Load Testing Procedure

#### 1. Load Test Configuration
```yaml
load_test_spec:
  tool: k6
  duration: "10m"
  stages:
    - duration: "2m"
      target: 10     # Ramp up to 10 users
    - duration: "5m" 
      target: 50     # Steady state with 50 concurrent users
    - duration: "2m"
      target: 100    # Peak load with 100 users
    - duration: "1m"
      target: 0      # Ramp down
  
  query_distribution:
    simple_queries: 60%    # Single-term, factual queries
    complex_queries: 30%   # Multi-term, analytical queries  
    code_queries: 10%     # Code search and debugging queries
  
  success_criteria:
    p95_latency: "≤ 150ms"
    p99_latency: "≤ 300ms" 
    error_rate: "≤ 1%"
    throughput: "≥ 100 RPS"
```

#### 2. K6 Load Test Script
```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// Custom metrics
export let errorRate = new Rate('errors');
export let retrievalLatency = new Trend('retrieval_latency');

// Test configuration
export let options = {
  stages: [
    { duration: '2m', target: 10 },
    { duration: '5m', target: 50 },
    { duration: '2m', target: 100 },
    { duration: '1m', target: 0 },
  ],
  thresholds: {
    'retrieval_latency': ['p(95)<150'], // 95% of requests under 150ms
    'retrieval_latency': ['p(99)<300'], // 99% of requests under 300ms
    'errors': ['rate<0.01'],            // Error rate under 1%
  },
};

// Query templates
const queries = [
  "What is machine learning?",
  "How to implement binary search in Python?",
  "Compare REST and GraphQL APIs",
  "Debug memory leak in Java application",
  "Explain quantum computing principles"
];

export default function() {
  // Select random query
  const query = queries[Math.floor(Math.random() * queries.length)];
  
  const payload = JSON.stringify({
    query: query,
    top_k: 10,
    include_reranking: true
  });

  const params = {
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ' + __ENV.API_TOKEN
    },
  };

  // Make request and measure latency
  const response = http.post('http://rag-api:8080/retrieve', payload, params);
  
  // Record custom metrics
  retrievalLatency.add(response.timings.duration);
  errorRate.add(response.status !== 200);
  
  // Verify response
  check(response, {
    'status is 200': (r) => r.status === 200,
    'response time < 300ms': (r) => r.timings.duration < 300,
    'has results': (r) => JSON.parse(r.body).results.length > 0,
  });

  sleep(1); // 1 second think time
}
```

#### 3. Performance Monitoring Setup
```python
# Prometheus metrics collection during load test
PERFORMANCE_METRICS = {
    "retrieval_latency_histogram": "histogram of retrieval request latencies",
    "query_throughput_counter": "total number of queries processed",
    "error_rate_gauge": "current error rate percentage",
    "cache_hit_rate_gauge": "cache hit rate during load test",
    "database_connection_pool": "active database connections",
    "gpu_utilization_gauge": "GPU utilization for reranker",
    "memory_usage_gauge": "system memory usage",
}

# Grafana dashboard queries for load test monitoring
GRAFANA_QUERIES = {
    "p95_latency": 'histogram_quantile(0.95, rate(retrieval_latency_bucket[1m]))',
    "p99_latency": 'histogram_quantile(0.99, rate(retrieval_latency_bucket[1m]))',
    "error_rate": 'rate(retrieval_errors_total[1m]) / rate(retrieval_requests_total[1m])',
    "throughput": 'rate(retrieval_requests_total[1m])',
    "cache_hit_rate": 'rate(cache_hits_total[1m]) / rate(cache_requests_total[1m])'
}
```

#### 4. Acceptance Criteria
- **Primary:** p95 retrieval latency ≤ 150ms during 10-minute load test
- **Secondary:**
  - p99 latency ≤ 300ms
  - Error rate ≤ 1% under peak load
  - Minimum throughput of 100 queries/second
  - System remains stable without memory leaks or crashes
  - Cache hit rate ≥ 80% during steady state

---

## Integrated Gate Validation

### End-to-End Test Suite
```python
#!/usr/bin/env python3
"""
Comprehensive RAG system gate validation
"""

class RAGGateValidator:
    """
    Comprehensive validation of all RAG production readiness gates
    """
    
    def __init__(self, config_path: str):
        self.config = load_config(config_path)
        self.results = {
            "gate_1_retrieval": {"status": "PENDING", "score": None},
            "gate_2_faithfulness": {"status": "PENDING", "score": None},
            "gate_3_performance": {"status": "PENDING", "score": None}
        }
    
    def validate_all_gates(self) -> Dict:
        """
        Run all gate validations in sequence
        """
        print("🚀 Starting RAG 2.0 Production Readiness Gate Validation")
        
        # Gate 1: Retrieval Quality
        print("\n📊 Gate 1: Evaluating Retrieval Quality (R@10 ≥ 0.90)")
        gate1_result = self.validate_retrieval_quality()
        self.results["gate_1_retrieval"] = gate1_result
        
        if gate1_result["status"] != "PASS":
            print("❌ Gate 1 FAILED - stopping validation")
            return self.generate_final_report()
        
        # Gate 2: Answer Faithfulness  
        print("\n🎯 Gate 2: Evaluating Answer Faithfulness (≥ 0.95)")
        gate2_result = self.validate_answer_faithfulness()
        self.results["gate_2_faithfulness"] = gate2_result
        
        if gate2_result["status"] != "PASS":
            print("❌ Gate 2 FAILED - stopping validation")
            return self.generate_final_report()
        
        # Gate 3: Performance
        print("\n⚡ Gate 3: Evaluating Performance (p95 ≤ 150ms)")
        gate3_result = self.validate_performance()
        self.results["gate_3_performance"] = gate3_result
        
        return self.generate_final_report()
    
    def validate_retrieval_quality(self) -> Dict:
        """Validate retrieval quality gate"""
        # Run retrieval evaluation
        eval_results = evaluate_retrieval_quality(
            self.config["golden_dataset_path"],
            self.config["rag_system"]
        )
        
        recall_score = eval_results["aggregate_metrics"]["recall_at_10"]
        latency_p95 = eval_results["performance_metrics"]["p95_retrieval_time_ms"]
        
        status = "PASS" if (recall_score >= 0.90 and latency_p95 <= 150) else "FAIL"
        
        return {
            "status": status,
            "recall_at_10": recall_score,
            "p95_latency_ms": latency_p95,
            "details": eval_results,
            "timestamp": datetime.now().isoformat()
        }
    
    def validate_answer_faithfulness(self) -> Dict:
        """Validate answer faithfulness gate"""
        # Run RAGAS evaluation
        faithfulness_results = evaluate_answer_faithfulness(
            self.config["faithfulness_dataset_path"],
            self.config["rag_system"]
        )
        
        faithfulness_score = faithfulness_results["faithfulness_score"]
        status = "PASS" if faithfulness_score >= 0.95 else "FAIL"
        
        return {
            "status": status,
            "faithfulness_score": faithfulness_score,
            "details": faithfulness_results,
            "timestamp": datetime.now().isoformat()
        }
    
    def validate_performance(self) -> Dict:
        """Validate performance gate using load testing"""
        # Execute K6 load test
        load_test_results = execute_load_test(self.config["load_test_config"])
        
        p95_latency = load_test_results["metrics"]["p95_latency"]
        error_rate = load_test_results["metrics"]["error_rate"]
        
        status = "PASS" if (p95_latency <= 150 and error_rate <= 0.01) else "FAIL"
        
        return {
            "status": status,
            "p95_latency_ms": p95_latency,
            "error_rate": error_rate,
            "throughput_rps": load_test_results["metrics"]["throughput"],
            "details": load_test_results,
            "timestamp": datetime.now().isoformat()
        }
    
    def generate_final_report(self) -> Dict:
        """Generate comprehensive gate validation report"""
        all_passed = all(
            result["status"] == "PASS" 
            for result in self.results.values()
        )
        
        report = {
            "overall_status": "PASS" if all_passed else "FAIL",
            "production_ready": all_passed,
            "gate_results": self.results,
            "summary": {
                "gates_passed": sum(1 for r in self.results.values() if r["status"] == "PASS"),
                "gates_failed": sum(1 for r in self.results.values() if r["status"] == "FAIL"),
                "validation_date": datetime.now().isoformat()
            },
            "next_steps": self.get_next_steps(all_passed),
            "sign_off_required": ["Tech Lead", "Product Owner", "Engineering Manager"]
        }
        
        # Save report
        with open('/reports/rag_gate_validation_report.json', 'w') as f:
            json.dump(report, f, indent=2)
        
        return report
    
    def get_next_steps(self, all_passed: bool) -> List[str]:
        """Determine next steps based on validation results"""
        if all_passed:
            return [
                "✅ All gates passed - system ready for production",
                "📋 Obtain required sign-offs from stakeholders", 
                "🚀 Schedule production deployment",
                "📊 Setup production monitoring and alerting",
                "📚 Update deployment documentation"
            ]
        else:
            failed_gates = [
                gate for gate, result in self.results.items() 
                if result["status"] == "FAIL"
            ]
            return [
                f"❌ Failed gates: {', '.join(failed_gates)}",
                "🔧 Address failures according to runbook procedures",
                "🔄 Re-run validation after fixes implemented",
                "📋 Review with engineering team for remediation plan"
            ]

# Usage
if __name__ == "__main__":
    validator = RAGGateValidator("/config/gate_validation.yaml")
    results = validator.validate_all_gates()
    
    print(f"\n🏁 Final Status: {results['overall_status']}")
    if results["production_ready"]:
        print("🎉 RAG 2.0 system is READY for production deployment!")
    else:
        print("⚠️ RAG 2.0 system requires fixes before production deployment")
```

---

## Go/No-Go Decision Framework

### Decision Matrix
| Gate | Weight | Pass Threshold | Current Score | Status | Impact on Go-Live |
|------|--------|---------------|---------------|---------|------------------|
| Retrieval Quality (R@10) | 40% | ≥ 0.90 | TBD | 🔴 PENDING | **BLOCKING** |
| Answer Faithfulness | 40% | ≥ 0.95 | TBD | 🔴 PENDING | **BLOCKING** |
| Performance (p95 latency) | 20% | ≤ 150ms | TBD | 🔴 PENDING | **BLOCKING** |

### Decision Rules
1. **GO Decision:** All three gates must achieve PASS status
2. **NO-GO Decision:** Any gate fails to meet minimum threshold
3. **CONDITIONAL GO:** Waiver process available only for performance gate with stakeholder approval

### Risk Assessment Matrix
```yaml
risk_levels:
  low_risk:
    criteria: "All gates pass with >10% margin"
    recommendation: "Proceed with full production rollout"
    monitoring: "Standard production monitoring"
  
  medium_risk:
    criteria: "All gates pass within 5% of threshold"
    recommendation: "Proceed with gradual rollout (5% -> 25% -> 100%)"
    monitoring: "Enhanced monitoring with auto-rollback triggers"
  
  high_risk:
    criteria: "Any gate fails or passes by <2% margin"  
    recommendation: "Do not proceed - address issues first"
    monitoring: "Full system review and remediation required"
```

### Stakeholder Sign-off Requirements

#### Required Approvals
```yaml
sign_off_matrix:
  technical_lead:
    required: true
    validates: "Technical implementation meets requirements"
    
  product_owner:
    required: true  
    validates: "System meets business requirements and user needs"
    
  engineering_manager:
    required: true
    validates: "Team ready to support production system"
    
  qa_lead:
    required: true
    validates: "Quality standards met and testing complete"
    
  devops_lead:
    required: false  # Optional but recommended
    validates: "Infrastructure ready for production load"
```

#### Sign-off Document Template
```markdown
# RAG 2.0 Production Readiness Sign-off

**System:** RAG 2.0 Retrieval & Generation System  
**Date:** [DATE]  
**Gate Validation Results:** [PASS/FAIL]

## Gate Results Summary
- **Retrieval Quality:** [SCORE] (Target: ≥0.90) [PASS/FAIL]
- **Answer Faithfulness:** [SCORE] (Target: ≥0.95) [PASS/FAIL]  
- **Performance:** [LATENCY]ms p95 (Target: ≤150ms) [PASS/FAIL]

## Stakeholder Approvals

### Technical Lead: [NAME]
- [ ] Technical implementation meets requirements
- [ ] Code quality standards satisfied
- [ ] Architecture review completed
- **Signature:** _________________ **Date:** _________

### Product Owner: [NAME]  
- [ ] Business requirements satisfied
- [ ] User acceptance criteria met
- [ ] Risk assessment acceptable
- **Signature:** _________________ **Date:** _________

### Engineering Manager: [NAME]
- [ ] Team ready for production support
- [ ] Runbooks and documentation complete
- [ ] Monitoring and alerting configured
- **Signature:** _________________ **Date:** _________

## Deployment Authorization
Based on the above validations and approvals:

**DECISION:** [ ] GO / [ ] NO-GO

**Authorized by:** [ENGINEERING DIRECTOR]  
**Signature:** _________________ **Date:** _________
```

---

## Monitoring and Alerting Post-Deployment

### Production Monitoring Requirements
```yaml
production_monitoring:
  metrics_collection:
    frequency: "5 seconds"
    retention: "90 days"
    
  key_metrics:
    - name: "retrieval_recall_at_10"
      target: ">= 0.88"  # 2% buffer from gate threshold
      alert_threshold: "< 0.85"
      
    - name: "answer_faithfulness_score"  
      target: ">= 0.93"  # 2% buffer from gate threshold
      alert_threshold: "< 0.90"
      
    - name: "retrieval_latency_p95"
      target: "<= 130ms"  # 20ms buffer from gate threshold
      alert_threshold: "> 180ms"
      
    - name: "system_error_rate"
      target: "<= 0.5%"
      alert_threshold: "> 1.0%"

  alerting_channels:
    critical: ["pagerduty", "slack-oncall"] 
    warning: ["slack-engineering", "email"]
    
  dashboard_url: "https://grafana.company.com/d/rag-production"
```

### Automated Rollback Triggers
```yaml
rollback_conditions:
  immediate_rollback:
    - "retrieval_recall_at_10 < 0.80 for 5 minutes"
    - "answer_faithfulness < 0.85 for 5 minutes"  
    - "error_rate > 5% for 3 minutes"
    - "retrieval_latency_p95 > 500ms for 10 minutes"
    
  gradual_rollback:
    - "retrieval_recall_at_10 < 0.85 for 15 minutes"
    - "answer_faithfulness < 0.90 for 15 minutes"
    - "retrieval_latency_p95 > 200ms for 20 minutes"
    
rollback_procedure:
  method: "automated_via_kubernetes"
  target_version: "last_known_good"
  notification: "immediate_to_oncall_team"
  validation_timeout: "5_minutes"
```

---

## Appendix

### A. Testing Environment Setup
```bash
# Environment preparation script
#!/bin/bash
set -e

echo "Setting up RAG 2.0 gate validation environment..."

# 1. Database setup
psql -d rag_test -f /sql/test_schema.sql
psql -d rag_test -f /sql/golden_dataset_import.sql

# 2. Load test models
docker run --gpus all -d --name rag-reranker \
  -p 8081:8080 \
  -v /models:/app/models \
  rag-reranker:latest

# 3. Start monitoring stack
docker-compose -f monitoring-stack.yml up -d

# 4. Verify environment health
python3 /scripts/verify_test_environment.py

echo "✅ Test environment ready for gate validation"
```

### B. Troubleshooting Guide
```yaml
common_issues:
  low_recall:
    symptoms: "R@10 < 0.90"
    causes: ["poor chunking", "embedding mismatch", "index issues"]
    solutions: ["review chunking strategy", "retrain embeddings", "rebuild indexes"]
    
  high_latency:  
    symptoms: "p95 > 150ms"
    causes: ["slow database", "reranker bottleneck", "memory issues"]
    solutions: ["tune database", "scale rerankers", "increase memory"]
    
  low_faithfulness:
    symptoms: "faithfulness < 0.95" 
    causes: ["irrelevant retrieval", "context truncation", "hallucination"]
    solutions: ["tune reranker", "increase context size", "improve prompts"]
```

### C. Gate Validation Checklist
- [ ] Golden dataset prepared and validated (1000+ queries)
- [ ] Test environment configured and healthy
- [ ] All evaluation scripts tested and working
- [ ] Monitoring dashboards configured
- [ ] Load testing infrastructure ready
- [ ] Manual review process established
- [ ] Stakeholders identified and available for sign-off
- [ ] Rollback procedures tested and documented
- [ ] Post-deployment monitoring configured
- [ ] Documentation updated and reviewed

---

**Document Control**
- **Next Review:** After each gate validation cycle
- **Change Approval:** Technical Lead + Product Owner  
- **Distribution:** Engineering Team, QA Team, Product Management
- **Related Documents:** CH37_RAG2.md, rag-quality.md, deployment runbooks