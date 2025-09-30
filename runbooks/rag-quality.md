# RAG Quality Tuning and Optimization Runbook

**Document Version:** 1.0  
**Last Updated:** 2025-09-30  
**Owner:** RAG Engineering Team  
**Review Cycle:** Monthly  

## Table of Contents
1. [Overview](#overview)
2. [Quality Metrics Monitoring](#quality-metrics-monitoring)
3. [Chunking Strategy Optimization](#chunking-strategy-optimization)
4. [Embedding Model Tuning](#embedding-model-tuning)
5. [BM25 Full-Text Search Optimization](#bm25-full-text-search-optimization)
6. [Reranker Threshold Tuning](#reranker-threshold-tuning)
7. [Performance vs Quality Trade-offs](#performance-vs-quality-trade-offs)
8. [Quality Degradation Troubleshooting](#quality-degradation-troubleshooting)
9. [A/B Testing Procedures](#ab-testing-procedures)
10. [Emergency Rollback Procedures](#emergency-rollback-procedures)

## Overview

This runbook provides step-by-step procedures for maintaining and optimizing RAG system quality to meet acceptance gates:
- **Retrieval R@10 ≥ 0.90**
- **Answer faithfulness ≥ 0.95**
- **p95 retrieval latency ≤ 150ms**

### Prerequisites
- Access to monitoring dashboards (Grafana/Prometheus)
- Database admin privileges for PostgreSQL
- Access to evaluation datasets
- Understanding of RAG metrics and benchmarks

---

## Quality Metrics Monitoring

### 1. Key Performance Indicators (KPIs)

#### Primary Quality Metrics
```yaml
quality_metrics:
  retrieval_recall_at_10:
    target: "≥ 0.90"
    measurement_frequency: "daily"
    alert_threshold: "< 0.85"
  
  answer_faithfulness:
    target: "≥ 0.95"
    measurement_frequency: "daily"
    alert_threshold: "< 0.90"
  
  retrieval_latency_p95:
    target: "≤ 150ms"
    measurement_frequency: "continuous"
    alert_threshold: "> 200ms"

secondary_metrics:
  precision_at_5: "≥ 0.85"
  mean_reciprocal_rank: "≥ 0.75"
  cache_hit_rate: "≥ 0.80"
  reranker_effectiveness: "≥ 0.15"  # Improvement over base retrieval
```

#### Monitoring Dashboard Queries
```promql
# Retrieval latency P95
histogram_quantile(0.95, rate(retrieval_duration_seconds_bucket[5m]))

# Query success rate
rate(retrieval_requests_total{status="success"}[5m]) / rate(retrieval_requests_total[5m])

# Cache hit ratio
rate(cache_hits_total[5m]) / rate(cache_requests_total[5m])

# Reranker processing time
histogram_quantile(0.95, rate(reranker_duration_seconds_bucket[5m]))
```

### 2. Quality Assessment Procedures

#### Daily Quality Check Script
```bash
#!/bin/bash
# daily_quality_check.sh

DATE=$(date +%Y-%m-%d)
LOG_FILE="/var/log/rag/quality_check_${DATE}.log"

echo "Starting daily RAG quality assessment - $(date)" | tee -a $LOG_FILE

# Run evaluation on golden dataset
python3 /opt/rag/scripts/evaluate_retrieval.py \
  --dataset /data/golden_eval_set.jsonl \
  --output /tmp/eval_results_${DATE}.json \
  --metrics recall@10,precision@5,mrr | tee -a $LOG_FILE

# Check latency metrics
psql -d rag_db -c "
SELECT 
  AVG(execution_time_ms) as avg_latency,
  PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY execution_time_ms) as p95_latency
FROM query_performance_log 
WHERE executed_at > NOW() - INTERVAL '24 hours';" | tee -a $LOG_FILE

# Alert if thresholds breached
python3 /opt/rag/scripts/check_quality_alerts.py \
  --results /tmp/eval_results_${DATE}.json \
  --alert-webhook $SLACK_WEBHOOK_URL | tee -a $LOG_FILE
```

---

## Chunking Strategy Optimization

### 1. Document Type-Specific Tuning

#### PDF Documents
```python
# Optimal chunking parameters for PDFs
PDF_CHUNKING_CONFIG = {
    "max_chunk_size": 1000,     # Characters
    "overlap": 200,             # Character overlap between chunks
    "min_chunk_size": 100,      # Minimum viable chunk size
    "respect_boundaries": ["section", "paragraph", "sentence"],
    "quality_threshold": 0.85,   # Semantic coherence score
}

# Tuning procedure
def tune_pdf_chunking():
    # Test different chunk sizes
    chunk_sizes = [500, 750, 1000, 1250, 1500]
    overlaps = [100, 150, 200, 250]
    
    best_config = None
    best_score = 0
    
    for size in chunk_sizes:
        for overlap in overlaps:
            config = {"max_chunk_size": size, "overlap": overlap}
            score = evaluate_chunking_quality(config, sample_documents)
            if score > best_score:
                best_score = score
                best_config = config
    
    return best_config, best_score
```

#### Source Code Repositories
```python
# Code-specific chunking optimization
CODE_CHUNKING_CONFIG = {
    "method": "tree_sitter_ast",
    "unit_types": ["function", "class", "method"],
    "include_context": ["imports", "docstrings", "type_hints"],
    "max_tokens": 2048,
    "preserve_syntax": True,
    "cross_reference_resolution": True
}

# Quality assessment for code chunks
def assess_code_chunk_quality(chunk):
    """
    Assess code chunk quality based on:
    - Syntactic completeness
    - Semantic coherence
    - Context preservation
    """
    quality_score = 0
    
    # Check syntax completeness
    if is_syntactically_complete(chunk):
        quality_score += 0.4
    
    # Check semantic coherence
    if has_sufficient_context(chunk):
        quality_score += 0.3
    
    # Check documentation presence
    if has_documentation(chunk):
        quality_score += 0.3
    
    return quality_score
```

### 2. Chunk Quality Evaluation

#### Semantic Coherence Scoring
```python
def evaluate_chunk_coherence(chunk_text, embedding_model):
    """
    Measure semantic coherence within a chunk
    """
    sentences = split_into_sentences(chunk_text)
    if len(sentences) < 2:
        return 1.0  # Single sentence is perfectly coherent
    
    embeddings = [embedding_model.encode(sent) for sent in sentences]
    
    # Calculate average pairwise cosine similarity
    similarities = []
    for i in range(len(embeddings)):
        for j in range(i+1, len(embeddings)):
            sim = cosine_similarity(embeddings[i], embeddings[j])
            similarities.append(sim)
    
    return np.mean(similarities)

# Coherence threshold tuning
COHERENCE_THRESHOLDS = {
    "excellent": 0.85,    # High coherence, optimal for retrieval
    "good": 0.70,         # Acceptable coherence
    "poor": 0.50,         # Requires re-chunking
    "unacceptable": 0.30  # Must be re-processed
}
```

### 3. Chunking Strategy A/B Testing

#### Procedure for Testing New Chunking Strategies
1. **Baseline Measurement**
   ```bash
   # Measure current performance
   python3 evaluate_current_chunking.py --output baseline_metrics.json
   ```

2. **Deploy Test Configuration**
   ```python
   # Deploy to 10% of traffic
   CHUNKING_A_B_CONFIG = {
       "strategy_a": "current_production",
       "strategy_b": "optimized_semantic_v2", 
       "traffic_split": 0.1,  # 10% to strategy_b
       "duration_days": 7,
       "success_criteria": {
           "recall_improvement": 0.02,  # 2% improvement
           "latency_degradation": 0.05   # Max 5% slower
       }
   }
   ```

3. **Monitor and Compare**
   ```sql
   -- Compare retrieval quality between strategies
   SELECT 
       chunking_strategy,
       AVG(recall_at_10) as avg_recall,
       AVG(precision_at_5) as avg_precision,
       AVG(query_latency_ms) as avg_latency
   FROM evaluation_results 
   WHERE test_date >= NOW() - INTERVAL '7 days'
   GROUP BY chunking_strategy;
   ```

---

## Embedding Model Tuning

### 1. Model Selection and Dimensionality

#### Performance vs Quality Trade-off Analysis
```python
EMBEDDING_MODEL_COMPARISON = {
    "sentence-transformers/all-MiniLM-L6-v2": {
        "dimensions": 384,
        "performance_score": 9.5,  # Very fast
        "quality_score": 7.0,      # Good quality
        "memory_usage_mb": 90
    },
    "sentence-transformers/all-mpnet-base-v2": {
        "dimensions": 768,
        "performance_score": 8.0,  # Fast
        "quality_score": 8.5,      # High quality
        "memory_usage_mb": 420
    },
    "BAAI/bge-large-en-v1.5": {
        "dimensions": 1024,
        "performance_score": 6.5,  # Slower
        "quality_score": 9.0,      # Excellent quality
        "memory_usage_mb": 1200
    }
}
```

#### Model Evaluation Procedure
```python
def evaluate_embedding_model(model_name, test_queries, document_corpus):
    """
    Comprehensive embedding model evaluation
    """
    model = SentenceTransformer(model_name)
    
    # Encode test corpus
    start_time = time.time()
    doc_embeddings = model.encode(document_corpus, show_progress_bar=True)
    encoding_time = time.time() - start_time
    
    # Evaluate retrieval quality
    recall_scores = []
    precision_scores = []
    
    for query, relevant_docs in test_queries:
        query_embedding = model.encode([query])
        similarities = cosine_similarity(query_embedding, doc_embeddings)[0]
        
        # Get top-k results
        top_k_indices = np.argsort(similarities)[::-1][:10]
        
        # Calculate metrics
        recall = calculate_recall_at_k(top_k_indices, relevant_docs, k=10)
        precision = calculate_precision_at_k(top_k_indices, relevant_docs, k=5)
        
        recall_scores.append(recall)
        precision_scores.append(precision)
    
    return {
        "model_name": model_name,
        "avg_recall_at_10": np.mean(recall_scores),
        "avg_precision_at_5": np.mean(precision_scores),
        "encoding_time_seconds": encoding_time,
        "model_size_mb": get_model_size_mb(model)
    }
```

### 2. Fine-tuning Procedures

#### Domain-Specific Fine-tuning
```python
# Fine-tuning configuration for domain adaptation
FINE_TUNING_CONFIG = {
    "base_model": "sentence-transformers/all-mpnet-base-v2",
    "training_data": "/data/domain_specific_pairs.json",
    "validation_split": 0.2,
    "epochs": 3,
    "batch_size": 16,
    "learning_rate": 2e-5,
    "warmup_steps": 100,
    "evaluation_steps": 500
}

def fine_tune_embedding_model(config):
    """
    Fine-tune embedding model for domain-specific performance
    """
    # Load training data
    train_examples = load_training_data(config["training_data"])
    
    # Split train/validation
    train_data, val_data = train_test_split(
        train_examples, 
        test_size=config["validation_split"]
    )
    
    # Initialize model and training
    model = SentenceTransformer(config["base_model"])
    train_dataloader = DataLoader(train_data, batch_size=config["batch_size"])
    
    # Define loss function (typically MultipleNegativesRankingLoss)
    train_loss = losses.MultipleNegativesRankingLoss(model)
    
    # Train model
    model.fit(
        train_objectives=[(train_dataloader, train_loss)],
        epochs=config["epochs"],
        warmup_steps=config["warmup_steps"],
        evaluator=SentenceEvaluator.from_input_examples(val_data),
        evaluation_steps=config["evaluation_steps"],
        output_path="./fine_tuned_model"
    )
    
    return model
```

---

## BM25 Full-Text Search Optimization

### 1. Stopwords and Preprocessing

#### Domain-Specific Stopword Lists
```python
# Base English stopwords
BASE_STOPWORDS = set(nltk.corpus.stopwords.words('english'))

# Domain-specific stopwords for technical documents
TECHNICAL_STOPWORDS = {
    'code', 'function', 'method', 'class', 'variable', 
    'parameter', 'return', 'value', 'type', 'object',
    'example', 'following', 'above', 'below', 'shown'
}

# Final stopword list
CUSTOM_STOPWORDS = BASE_STOPWORDS.union(TECHNICAL_STOPWORDS)

# PostgreSQL custom dictionary setup
CREATE_CUSTOM_DICT_SQL = """
CREATE TEXT SEARCH DICTIONARY custom_english (
    TEMPLATE = snowball,
    Language = english,
    StopWords = custom_stopwords
);

CREATE TEXT SEARCH CONFIGURATION custom_config (COPY = english);
ALTER TEXT SEARCH CONFIGURATION custom_config
    ALTER MAPPING FOR asciiword WITH custom_english, simple;
"""
```

#### Text Preprocessing Pipeline
```python
def optimize_text_preprocessing(text):
    """
    Optimized text preprocessing for BM25 search
    """
    # Normalize whitespace and remove special characters
    text = re.sub(r'\s+', ' ', text)
    text = re.sub(r'[^\w\s-]', ' ', text)
    
    # Handle code snippets (preserve structure)
    code_blocks = extract_code_blocks(text)
    for i, block in enumerate(code_blocks):
        text = text.replace(block, f"CODE_BLOCK_{i}")
    
    # Expand contractions
    text = expand_contractions(text)
    
    # Handle technical terms and acronyms
    text = preserve_technical_terms(text)
    
    # Stemming with technical term preservation
    tokens = word_tokenize(text.lower())
    stemmer = PorterStemmer()
    
    processed_tokens = []
    for token in tokens:
        if token in TECHNICAL_TERMS_DICT:
            processed_tokens.append(TECHNICAL_TERMS_DICT[token])
        elif token not in CUSTOM_STOPWORDS:
            processed_tokens.append(stemmer.stem(token))
    
    return ' '.join(processed_tokens)
```

### 2. BM25 Parameter Tuning

#### Optimal BM25 Parameters
```python
BM25_PARAMETERS = {
    "k1": 1.2,     # Term frequency normalization (1.2-2.0)
    "b": 0.75,     # Length normalization (0.0-1.0)
    "epsilon": 0.25  # IDF normalization
}

def tune_bm25_parameters(query_set, document_corpus, relevance_judgments):
    """
    Grid search for optimal BM25 parameters
    """
    k1_values = [0.8, 1.0, 1.2, 1.4, 1.6, 1.8, 2.0]
    b_values = [0.0, 0.25, 0.5, 0.75, 1.0]
    
    best_params = None
    best_score = 0
    
    for k1 in k1_values:
        for b in b_values:
            # Configure BM25 with current parameters
            bm25 = BM25Okapi(document_corpus, k1=k1, b=b)
            
            # Evaluate on query set
            total_score = 0
            for query, relevant_docs in query_set:
                scores = bm25.get_scores(query.split())
                top_docs = np.argsort(scores)[::-1][:10]
                
                # Calculate NDCG@10
                ndcg_score = calculate_ndcg(top_docs, relevant_docs, k=10)
                total_score += ndcg_score
            
            avg_score = total_score / len(query_set)
            
            if avg_score > best_score:
                best_score = avg_score
                best_params = {"k1": k1, "b": b}
    
    return best_params, best_score
```

#### PostgreSQL Full-Text Search Configuration
```sql
-- Update PostgreSQL FTS configuration for optimal BM25-like scoring
ALTER TEXT SEARCH CONFIGURATION custom_config
    ALTER MAPPING FOR word WITH custom_english;

-- Custom ranking function for BM25-style scoring  
CREATE OR REPLACE FUNCTION bm25_rank(
    tsvector_doc tsvector,
    tsquery_query tsquery,
    k1 float DEFAULT 1.2,
    b float DEFAULT 0.75
) RETURNS float AS $$
DECLARE
    doc_length int;
    avg_doc_length float;
    tf float;
    idf float;
    score float;
BEGIN
    -- Simplified BM25 calculation
    -- (Full implementation would require more complex calculations)
    doc_length := array_length(tsvector_to_array(tsvector_doc), 1);
    
    SELECT AVG(array_length(tsvector_to_array(content_tsvector), 1))
    INTO avg_doc_length
    FROM documents;
    
    -- Calculate BM25 score approximation
    score := ts_rank_cd(tsvector_doc, tsquery_query, 1) * 
             (k1 + 1) / (k1 * (1 - b + b * (doc_length / avg_doc_length)) + 1);
    
    RETURN score;
END;
$$ LANGUAGE plpgsql;
```

---

## Reranker Threshold Tuning

### 1. Score Distribution Analysis

#### Understanding Reranker Score Distributions
```python
def analyze_reranker_score_distribution(reranker_results):
    """
    Analyze reranker score distributions to set optimal thresholds
    """
    scores = [result['score'] for result in reranker_results]
    
    statistics = {
        "mean": np.mean(scores),
        "median": np.median(scores),
        "std": np.std(scores),
        "min": np.min(scores),
        "max": np.max(scores),
        "percentiles": {
            "p10": np.percentile(scores, 10),
            "p25": np.percentile(scores, 25),
            "p75": np.percentile(scores, 75),
            "p90": np.percentile(scores, 90),
            "p95": np.percentile(scores, 95)
        }
    }
    
    # Plot score distribution
    plt.figure(figsize=(12, 6))
    plt.subplot(1, 2, 1)
    plt.hist(scores, bins=50, alpha=0.7, edgecolor='black')
    plt.title('Reranker Score Distribution')
    plt.xlabel('Score')
    plt.ylabel('Frequency')
    
    plt.subplot(1, 2, 2)
    plt.boxplot(scores)
    plt.title('Score Distribution (Box Plot)')
    plt.ylabel('Score')
    
    plt.tight_layout()
    plt.savefig('/tmp/reranker_score_distribution.png')
    
    return statistics
```

### 2. Threshold Optimization

#### ROC-Based Threshold Selection
```python
def optimize_reranker_threshold(scores, relevance_labels):
    """
    Find optimal threshold using ROC analysis
    """
    from sklearn.metrics import roc_curve, auc
    
    # Calculate ROC curve
    fpr, tpr, thresholds = roc_curve(relevance_labels, scores)
    roc_auc = auc(fpr, tpr)
    
    # Find optimal threshold (Youden's J statistic)
    optimal_idx = np.argmax(tpr - fpr)
    optimal_threshold = thresholds[optimal_idx]
    
    # Calculate metrics at optimal threshold
    predictions = (scores >= optimal_threshold).astype(int)
    precision = precision_score(relevance_labels, predictions)
    recall = recall_score(relevance_labels, predictions)
    f1 = f1_score(relevance_labels, predictions)
    
    return {
        "optimal_threshold": optimal_threshold,
        "roc_auc": roc_auc,
        "precision": precision,
        "recall": recall,
        "f1_score": f1,
        "tpr_at_threshold": tpr[optimal_idx],
        "fpr_at_threshold": fpr[optimal_idx]
    }
```

#### Dynamic Threshold Adjustment
```python
class DynamicThresholdManager:
    """
    Dynamically adjust reranker thresholds based on query characteristics
    """
    
    def __init__(self):
        self.base_threshold = 0.5
        self.thresholds = {
            "high_precision": 0.8,    # For critical queries
            "balanced": 0.5,          # Default threshold
            "high_recall": 0.2        # For comprehensive search
        }
    
    def get_threshold(self, query, query_type=None, user_context=None):
        """
        Determine appropriate threshold based on query characteristics
        """
        # Analyze query complexity
        query_complexity = self._analyze_query_complexity(query)
        
        # Determine strategy
        if user_context and user_context.get("precision_priority"):
            return self.thresholds["high_precision"]
        elif query_complexity > 0.7:  # Complex queries need more recall
            return self.thresholds["high_recall"]
        else:
            return self.thresholds["balanced"]
    
    def _analyze_query_complexity(self, query):
        """
        Analyze query complexity to inform threshold selection
        """
        complexity_indicators = [
            len(query.split()) > 10,           # Long queries
            "compare" in query.lower(),        # Comparison queries  
            "relationship" in query.lower(),   # Relational queries
            query.count("and") > 1,           # Multi-faceted queries
            query.count("?") > 1              # Multiple questions
        ]
        
        return sum(complexity_indicators) / len(complexity_indicators)
```

---

## Performance vs Quality Trade-offs

### 1. Latency-Quality Optimization

#### Performance Profiles
```python
PERFORMANCE_PROFILES = {
    "ultra_fast": {
        "max_candidates": 50,
        "reranker_enabled": False,
        "embedding_dimensions": 384,
        "expected_latency_ms": 50,
        "expected_recall": 0.75
    },
    "balanced": {
        "max_candidates": 100,
        "reranker_enabled": True,
        "reranker_top_k": 20,
        "embedding_dimensions": 768,
        "expected_latency_ms": 150,
        "expected_recall": 0.88
    },
    "high_quality": {
        "max_candidates": 200,
        "reranker_enabled": True,
        "reranker_top_k": 50,
        "embedding_dimensions": 1024,
        "expected_latency_ms": 300,
        "expected_recall": 0.92
    }
}

def select_performance_profile(query_context):
    """
    Select appropriate performance profile based on query context
    """
    if query_context.get("real_time_required"):
        return PERFORMANCE_PROFILES["ultra_fast"]
    elif query_context.get("quality_critical"):
        return PERFORMANCE_PROFILES["high_quality"]
    else:
        return PERFORMANCE_PROFILES["balanced"]
```

### 2. Resource Utilization Optimization

#### Memory vs Performance Trade-offs
```python
def optimize_memory_usage():
    """
    Optimize memory usage while maintaining performance targets
    """
    optimizations = {
        "embedding_quantization": {
            "method": "int8_quantization",
            "memory_reduction": 0.75,  # 75% reduction
            "quality_impact": 0.02     # 2% degradation
        },
        "index_compression": {
            "method": "pq_compression", 
            "memory_reduction": 0.60,   # 60% reduction
            "quality_impact": 0.05      # 5% degradation
        },
        "cache_optimization": {
            "method": "lru_with_priority",
            "memory_reduction": 0.30,   # 30% reduction
            "latency_impact": 0.10      # 10% increase
        }
    }
    
    return optimizations

# Monitor memory usage
def monitor_memory_usage():
    """
    Monitor and alert on memory usage patterns
    """
    psutil_process = psutil.Process()
    memory_info = psutil_process.memory_info()
    
    metrics = {
        "rss_mb": memory_info.rss / 1024 / 1024,
        "vms_mb": memory_info.vms / 1024 / 1024,
        "memory_percent": psutil_process.memory_percent(),
        "gpu_memory_mb": get_gpu_memory_usage()
    }
    
    # Alert thresholds
    if metrics["memory_percent"] > 85:
        send_alert("High memory usage detected", metrics)
    
    return metrics
```

---

## Quality Degradation Troubleshooting

### 1. Common Issues and Solutions

#### Retrieval Quality Degradation
```python
COMMON_ISSUES = {
    "low_recall": {
        "symptoms": ["R@10 < 0.85", "Missing relevant documents"],
        "causes": [
            "Overly restrictive chunking",
            "Embedding model mismatch", 
            "Index corruption",
            "Stale embeddings"
        ],
        "solutions": [
            "Increase chunk overlap",
            "Re-evaluate embedding model",
            "Rebuild indexes",
            "Re-embed documents"
        ]
    },
    "high_latency": {
        "symptoms": ["p95 > 200ms", "Timeout errors"],
        "causes": [
            "Index not in memory",
            "Too many candidates",
            "Reranker bottleneck",
            "Database locks"
        ],
        "solutions": [
            "Increase RAM allocation",
            "Reduce candidate pool size",
            "Scale reranker instances", 
            "Optimize query patterns"
        ]
    },
    "poor_faithfulness": {
        "symptoms": ["Faithfulness < 0.90", "Hallucinated answers"],
        "causes": [
            "Low-quality chunks",
            "Irrelevant retrieval",
            "Context truncation",
            "Prompt engineering issues"
        ],
        "solutions": [
            "Improve chunking strategy",
            "Tune reranker thresholds",
            "Increase context window",
            "Review prompt templates"
        ]
    }
}
```

#### Diagnostic Procedures
```python
def diagnose_quality_issues():
    """
    Comprehensive quality diagnostics
    """
    diagnostics = {}
    
    # Check retrieval quality
    diagnostics["retrieval"] = check_retrieval_quality()
    
    # Check embedding quality
    diagnostics["embeddings"] = check_embedding_quality()
    
    # Check index health
    diagnostics["indexes"] = check_index_health()
    
    # Check system resources
    diagnostics["resources"] = check_system_resources()
    
    # Generate recommendations
    recommendations = generate_recommendations(diagnostics)
    
    return {
        "diagnostics": diagnostics,
        "recommendations": recommendations,
        "severity": assess_severity(diagnostics)
    }

def check_retrieval_quality():
    """
    Check retrieval system quality metrics
    """
    # Run evaluation on test set
    results = run_retrieval_evaluation()
    
    quality_checks = {
        "recall_at_10": results["recall@10"] >= 0.90,
        "precision_at_5": results["precision@5"] >= 0.85,
        "mrr": results["mrr"] >= 0.75,
        "latency_p95": results["latency_p95"] <= 150
    }
    
    return {
        "metrics": results,
        "passed_checks": quality_checks,
        "overall_health": all(quality_checks.values())
    }
```

### 2. Automated Quality Monitoring

#### Quality Monitoring Pipeline
```python
class QualityMonitor:
    """
    Automated quality monitoring and alerting system
    """
    
    def __init__(self):
        self.thresholds = {
            "recall_at_10": 0.85,      # Warning threshold
            "faithfulness": 0.90,       # Warning threshold  
            "latency_p95": 200,         # Warning threshold (ms)
            "error_rate": 0.05          # Warning threshold (5%)
        }
    
    def run_quality_check(self):
        """
        Run comprehensive quality check
        """
        current_metrics = self.collect_metrics()
        
        alerts = []
        for metric, value in current_metrics.items():
            if metric in self.thresholds:
                threshold = self.thresholds[metric]
                
                if metric == "latency_p95" or metric == "error_rate":
                    # Higher is worse
                    if value > threshold:
                        alerts.append(self.create_alert(metric, value, threshold))
                else:
                    # Lower is worse  
                    if value < threshold:
                        alerts.append(self.create_alert(metric, value, threshold))
        
        if alerts:
            self.send_alerts(alerts)
        
        return {
            "metrics": current_metrics,
            "alerts": alerts,
            "status": "healthy" if not alerts else "degraded"
        }
    
    def create_alert(self, metric, current_value, threshold):
        """
        Create structured alert for quality degradation
        """
        severity = self.calculate_severity(metric, current_value, threshold)
        
        return {
            "metric": metric,
            "current_value": current_value,
            "threshold": threshold,
            "severity": severity,
            "timestamp": datetime.now(),
            "runbook_link": f"/runbooks/rag-quality.md#{metric.replace('_', '-')}"
        }
```

---

## A/B Testing Procedures

### 1. Experiment Design

#### A/B Test Configuration
```python
AB_TEST_CONFIG = {
    "test_name": "chunking_strategy_v2",
    "hypothesis": "Semantic chunking improves recall by 3%",
    "traffic_allocation": {
        "control": 0.8,   # 80% current system
        "treatment": 0.2   # 20% new system
    },
    "duration_days": 14,
    "success_metrics": {
        "primary": "recall_at_10",
        "secondary": ["precision_at_5", "latency_p95", "user_satisfaction"]
    },
    "guardrail_metrics": {
        "max_latency_increase": 0.20,  # 20% max increase
        "min_recall_threshold": 0.85    # Don't go below 0.85
    }
}
```

#### Statistical Analysis Framework
```python
def analyze_ab_test_results(control_metrics, treatment_metrics, config):
    """
    Statistical analysis of A/B test results
    """
    from scipy import stats
    
    results = {}
    
    for metric in config["success_metrics"]["primary"]:
        # Extract metric values
        control_values = [m[metric] for m in control_metrics]
        treatment_values = [m[metric] for m in treatment_metrics]
        
        # Perform statistical test
        statistic, p_value = stats.ttest_ind(control_values, treatment_values)
        
        # Calculate effect size (Cohen's d)
        pooled_std = np.sqrt(((len(control_values) - 1) * np.var(control_values) + 
                             (len(treatment_values) - 1) * np.var(treatment_values)) / 
                            (len(control_values) + len(treatment_values) - 2))
        
        cohens_d = (np.mean(treatment_values) - np.mean(control_values)) / pooled_std
        
        # Determine significance
        is_significant = p_value < 0.05
        
        results[metric] = {
            "control_mean": np.mean(control_values),
            "treatment_mean": np.mean(treatment_values),
            "relative_improvement": (np.mean(treatment_values) - np.mean(control_values)) / np.mean(control_values),
            "p_value": p_value,
            "cohens_d": cohens_d,
            "is_significant": is_significant,
            "confidence_interval": stats.t.interval(0.95, len(treatment_values)-1, 
                                                   loc=np.mean(treatment_values), 
                                                   scale=stats.sem(treatment_values))
        }
    
    return results
```

### 2. Rollout Strategy

#### Gradual Rollout Procedure
```python
ROLLOUT_STAGES = {
    "stage_1": {"traffic_percent": 5, "duration_hours": 24, "success_threshold": 0.85},
    "stage_2": {"traffic_percent": 20, "duration_hours": 48, "success_threshold": 0.88}, 
    "stage_3": {"traffic_percent": 50, "duration_hours": 72, "success_threshold": 0.90},
    "stage_4": {"traffic_percent": 100, "duration_hours": 168, "success_threshold": 0.90}
}

def execute_gradual_rollout(new_configuration):
    """
    Execute gradual rollout with automated monitoring
    """
    for stage_name, stage_config in ROLLOUT_STAGES.items():
        print(f"Starting {stage_name}: {stage_config['traffic_percent']}% traffic")
        
        # Update traffic routing
        update_traffic_routing(stage_config["traffic_percent"])
        
        # Monitor for duration
        monitor_results = monitor_stage(stage_config["duration_hours"])
        
        # Check success criteria
        if monitor_results["recall_at_10"] < stage_config["success_threshold"]:
            print(f"Stage {stage_name} failed success criteria. Rolling back.")
            rollback_to_previous_configuration()
            return False
        
        print(f"Stage {stage_name} successful. Proceeding to next stage.")
    
    print("Rollout completed successfully!")
    return True
```

---

## Emergency Rollback Procedures

### 1. Automated Rollback Triggers

#### Circuit Breaker Configuration
```python
CIRCUIT_BREAKER_CONFIG = {
    "error_rate_threshold": 0.10,        # 10% error rate
    "latency_p99_threshold": 1000,       # 1 second p99 latency
    "recall_degradation_threshold": 0.10, # 10% recall drop
    "consecutive_failures": 5,            # 5 consecutive failures
    "rollback_timeout_seconds": 300       # 5 minute rollback timeout
}

class EmergencyRollback:
    """
    Automated emergency rollback system
    """
    
    def __init__(self):
        self.rollback_stack = []  # Stack of previous configurations
        self.monitoring_active = True
    
    def monitor_system_health(self):
        """
        Continuous monitoring with automatic rollback triggers
        """
        while self.monitoring_active:
            metrics = collect_current_metrics()
            
            # Check circuit breaker conditions
            if self.should_trigger_rollback(metrics):
                print("EMERGENCY: Triggering automatic rollback")
                self.execute_emergency_rollback()
                self.send_emergency_alert(metrics)
                break
            
            time.sleep(30)  # Check every 30 seconds
    
    def should_trigger_rollback(self, metrics):
        """
        Determine if rollback should be triggered based on metrics
        """
        triggers = [
            metrics.get("error_rate", 0) > CIRCUIT_BREAKER_CONFIG["error_rate_threshold"],
            metrics.get("latency_p99", 0) > CIRCUIT_BREAKER_CONFIG["latency_p99_threshold"],
            metrics.get("recall_drop", 0) > CIRCUIT_BREAKER_CONFIG["recall_degradation_threshold"]
        ]
        
        return any(triggers)
    
    def execute_emergency_rollback(self):
        """
        Execute emergency rollback to last known good configuration
        """
        if not self.rollback_stack:
            print("ERROR: No rollback configuration available")
            return False
        
        # Get last known good configuration
        previous_config = self.rollback_stack.pop()
        
        try:
            # Apply previous configuration
            self.apply_configuration(previous_config)
            
            # Verify rollback success
            time.sleep(60)  # Wait for system to stabilize
            metrics = collect_current_metrics()
            
            if self.verify_rollback_success(metrics):
                print("Emergency rollback completed successfully")
                return True
            else:
                print("Rollback verification failed")
                return False
                
        except Exception as e:
            print(f"Rollback execution failed: {str(e)}")
            return False
```

### 2. Manual Rollback Procedures

#### Step-by-Step Manual Rollback
```bash
#!/bin/bash
# manual_rollback.sh - Emergency manual rollback script

echo "=== RAG SYSTEM EMERGENCY ROLLBACK ==="
echo "Timestamp: $(date)"

# Step 1: Stop current RAG services
echo "1. Stopping RAG services..."
kubectl scale deployment rag-retriever --replicas=0
kubectl scale deployment rag-reranker --replicas=0

# Step 2: Restore database configuration
echo "2. Restoring database configuration..."
psql -d rag_db -f /backup/last_known_good_schema.sql

# Step 3: Restore model configurations
echo "3. Restoring model configurations..."
cp /backup/embedding_config.json /opt/rag/config/
cp /backup/reranker_config.json /opt/rag/config/

# Step 4: Restart services with previous configuration
echo "4. Restarting services..."
kubectl scale deployment rag-retriever --replicas=3
kubectl scale deployment rag-reranker --replicas=2

# Step 5: Verify rollback
echo "5. Verifying rollback..."
sleep 30
python3 /opt/rag/scripts/verify_rollback.py

echo "=== ROLLBACK COMPLETED ==="
echo "Check monitoring dashboard for system health"
```

#### Rollback Verification Checklist
- [ ] Services are running and healthy
- [ ] Database queries return expected results
- [ ] Retrieval latency is within acceptable bounds
- [ ] Quality metrics return to baseline levels
- [ ] No error spikes in monitoring dashboards
- [ ] End-to-end tests pass successfully

---

## Maintenance Schedule

### Daily Tasks
- [ ] Review quality metrics dashboard
- [ ] Check system health alerts
- [ ] Monitor query performance logs
- [ ] Verify cache hit rates

### Weekly Tasks  
- [ ] Run comprehensive evaluation on test dataset
- [ ] Analyze A/B test results (if running)
- [ ] Review and update monitoring thresholds
- [ ] Performance optimization review

### Monthly Tasks
- [ ] Deep quality analysis and reporting
- [ ] Model performance benchmarking
- [ ] Capacity planning review
- [ ] Update documentation and runbooks

### Quarterly Tasks
- [ ] Complete system architecture review
- [ ] Evaluate new embedding models and techniques
- [ ] Disaster recovery testing
- [ ] Security and compliance audit

---

**Document Control**
- **Next Review Date:** 2025-10-30
- **Approval Required For Changes:** RAG Engineering Team Lead
- **Distribution:** Engineering Team, Operations Team, Management
- **Related Documents:** CH37_RAG2.md, rag_gate.md, monitoring runbooks