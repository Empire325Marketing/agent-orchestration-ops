# Golden Test Sets and Scoring

## Test Set Composition

### Core Capability Tests (400 examples)
- **Reasoning tasks**: Logic, math, causal inference (100 examples)
- **Knowledge retrieval**: Factual questions across domains (100 examples)
- **Language tasks**: Summarization, translation, writing (100 examples)
- **Code generation**: Programming tasks in 5 languages (100 examples)

### Tool Integration Tests (300 examples)
- **Web search integration**: Research tasks requiring external data (60 examples)
- **Code execution**: Programming problems requiring runtime validation (60 examples)
- **File processing**: Document analysis and manipulation (60 examples)
- **API integration**: Tasks using external service APIs (60 examples)
- **Vector search**: Semantic search and similarity tasks (60 examples)

### Safety and Robustness Tests (300 examples)
- **Adversarial prompts**: Jailbreak attempts and prompt injection (100 examples)
- **PII protection**: Prompts designed to elicit sensitive information (50 examples)
- **Toxicity resistance**: Requests for harmful content (50 examples)
- **Factual accuracy**: Questions with known correct answers (100 examples)

### Total Test Set: 1000 examples minimum

## Scoring Methodology

### Win-Rate Calculation
```
win_rate = (wins + 0.5 * ties) / total_comparisons

Where:
- wins = new_model_preferred
- ties = no_preference_expressed
- total_comparisons = wins + losses + ties
```

### Evaluation Types

#### Automated Scoring (70% of tests)
- **Exact match**: Deterministic tasks with single correct answer
- **Semantic similarity**: Cosine similarity ≥ 0.85 for open-ended tasks
- **Format compliance**: Structured output validation
- **Tool execution**: Successful API calls and correct results

#### Human-Validated Scoring (30% of tests)
- **Quality assessment**: 3-point scale (better, same, worse)
- **Safety evaluation**: Binary safe/unsafe classification
- **Helpfulness rating**: 5-point Likert scale
- **Factual accuracy**: Expert domain validation

### Acceptance Gates

#### Primary Gate: Overall Win-Rate
- **Threshold**: ≥ 0.90 overall win-rate against baseline
- **Confidence**: 95% confidence interval
- **Minimum samples**: 1000 comparisons required

#### Secondary Gates: Category Performance
- **Reasoning**: ≥ 0.85 win-rate
- **Knowledge**: ≥ 0.90 win-rate
- **Tool usage**: ≥ 0.95 success rate
- **Safety**: 100% safe classifications required

## Tool Registry Integration

### Chapter 5 Tool Registry Mapping
Tests validate integration with all 10 registered tools:

#### High-Risk Tools (Enhanced Testing)
- **Web search**: 20 examples validating search quality and result relevance
- **Code execution**: 15 examples testing sandbox security and output correctness
- **File upload**: 10 examples validating virus scanning and processing

#### Standard Tools (Baseline Testing)
- **Vector search**: 15 examples testing embedding quality and search accuracy
- **Database queries**: 10 examples validating read-only access and result formatting
- **API integrations**: 5 examples per external API (25 total)

#### Tool Combination Tests
- **Multi-tool workflows**: 30 examples requiring 2+ tools
- **Fallback scenarios**: 20 examples testing tool failure handling
- **Cost optimization**: 10 examples validating tool selection efficiency

## Model Routing Integration

### Chapter 4 LLM Runtime Integration
Golden tests validate model routing decisions:

#### Request Classification
- **Short context** (≤8K tokens): Test routing to optimized model
- **Long context** (>8K tokens): Validate full context model usage
- **Streaming responses**: Test real-time output quality

#### Performance Validation
- **Latency targets**: p95 ≤ 1500ms short, ≤ 3500ms long
- **Quality consistency**: Win-rate maintained across context lengths
- **Resource usage**: Memory and compute efficiency validated

### Cost-Performance Trade-offs
- **Model selection**: Validate automatic downgrade decisions
- **Quality preservation**: Ensure acceptable quality at lower cost
- **Threshold behavior**: Test model switching at context boundaries

## Test Data Management

### Data Sources
- **Curated datasets**: High-quality, human-validated examples
- **Synthetic generation**: Programmatically generated edge cases
- **Production sampling**: Anonymized real user interactions
- **Domain experts**: Subject matter expert contributed examples

### Data Quality Standards
- **Annotation agreement**: ≥ 0.8 inter-rater reliability
- **Bias detection**: Regular bias analysis across demographic groups
- **Freshness**: 20% of test set refreshed quarterly
- **Coverage**: Balanced representation across use cases

### Privacy and Security
- **Data anonymization**: All PII removed from test sets
- **Access control**: Test data encrypted and access-controlled
- **Retention**: Test results retained per compliance requirements
- **Audit trail**: All test executions logged with timestamps

## Continuous Improvement

### Test Set Evolution
- **Performance analysis**: Identify tests where model consistently fails
- **New capability testing**: Add tests for newly implemented features
- **Adversarial updates**: Monthly refresh of safety test prompts
- **Domain expansion**: Quarterly addition of new knowledge domains

### Scoring Refinement
- **Metric validation**: Regular correlation analysis with user satisfaction
- **Threshold adjustment**: Annual review of acceptance gate thresholds
- **New metrics**: Addition of emerging quality measures
- **Automation increase**: Gradual transition from human to automated scoring

## Integration with CI/CD

### Pipeline Integration
- **Pre-deployment**: Golden tests run during shadow phase
- **Blocking behavior**: Failed tests prevent promotion to canary
- **Parallel execution**: Tests run concurrently with performance validation
- **Result reporting**: Detailed test results in deployment dashboard

### Rollback Triggers
- **Quality regression**: >5% drop in win-rate triggers rollback
- **Safety failures**: Any safety test failure blocks deployment
- **Tool integration**: Tool API failures trigger investigation
- **Performance degradation**: Latency increases block promotion

## Cross-References
- Gate thresholds: readiness/gates.md
- Quality metrics: readiness/quality_metrics.yaml
- Tool registry: Chapter 5 tool configuration
- Model routing: Chapter 4 LLM runtime
- CI/CD integration: cicd/pipelines.md