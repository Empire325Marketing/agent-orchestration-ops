# Speech I/O Readiness Gate (DW-03)

## Gate Criteria

### ASR (Automatic Speech Recognition) Readiness
- **Model Loading**: Faster Whisper large-v2 model loaded successfully
- **Processing Speed**: Real-time factor < 0.5 for 10s audio samples
- **Accuracy**: Word Error Rate (WER) < 5% on clean English test set
- **Latency**: P95 processing time < 2s for 10s audio clips
- **Error Rate**: < 3% request failures over 10 minute window
- **Resource Usage**: GPU memory < 4GB, system memory < 2GB

### TTS (Text-to-Speech) Readiness
- **Model Loading**: Primary voice models loaded (en_US-lessac-medium minimum)
- **Generation Speed**: P95 synthesis time < 2s for 100 character inputs
- **Quality**: MOS score > 4.0 for primary English voices (manual validation)
- **Latency**: P95 total response time < 1s for short texts (< 50 chars)
- **Error Rate**: < 2% synthesis failures over 10 minute window
- **Audio Quality**: No artifacts in generated samples (spot check)

## Health Check Commands

```bash
# ASR Health Check
curl -X POST http://localhost:8080/v1/speech/asr/health \
  -H "Content-Type: application/json" \
  -d '{"test": "basic"}' \
  --max-time 5

# TTS Health Check
curl -X POST http://localhost:8080/v1/speech/tts/health \
  -H "Content-Type: application/json" \
  -d '{"test": "Hello world"}' \
  --max-time 3

# Model Status Check
curl http://localhost:8080/v1/speech/models/status
```

## Acceptance Tests

### ASR Test Suite
```bash
# Test 1: Clean audio transcription
./test_asr_clean.sh
# Expected: WER < 3%, latency < 1.5s

# Test 2: Noisy audio handling
./test_asr_noise.sh
# Expected: WER < 8%, no crashes

# Test 3: Multi-language support
./test_asr_multilang.sh
# Expected: Proper language detection, WER < 6%

# Test 4: Long audio processing
./test_asr_long.sh
# Expected: 60s audio processed < 5s, memory stable
```

### TTS Test Suite
```bash
# Test 1: Voice quality
./test_tts_quality.sh
# Expected: MOS > 4.0, no artifacts

# Test 2: Speed variations
./test_tts_speed.sh
# Expected: 0.5x-2.0x range functional

# Test 3: Text handling
./test_tts_text.sh
# Expected: Numbers, punctuation, abbreviations handled

# Test 4: Concurrent requests
./test_tts_concurrent.sh
# Expected: 10 parallel requests < 3s each
```

## Monitoring Queries

### Critical Metrics (Grafana/Prometheus)
```promql
# ASR processing speed (should be < 0.5)
primarch:speech_asr_realtime_factor

# TTS latency P95 (should be < 2s)
histogram_quantile(0.95, rate(primarch_speech_tts_generation_duration_seconds_bucket[5m]))

# ASR error rate (should be < 3%)
(100 - primarch:speech_asr_success_rate)

# TTS error rate (should be < 2%)
(100 - primarch:speech_tts_success_rate)

# Model availability
primarch_speech_asr_model_loaded + primarch_speech_tts_models_loaded
```

## Failure Scenarios & Recovery

### ASR Failures
1. **Model Load Failure**
   - Symptom: `primarch_speech_asr_model_loaded = 0`
   - Recovery: Restart service, check model files, fallback to CPU
   - Escalation: Page on-call if > 5 min downtime

2. **GPU OOM**
   - Symptom: CUDA errors, slow processing
   - Recovery: Reduce batch size, restart with smaller model
   - Prevention: Monitor GPU memory usage

3. **Audio Format Issues**
   - Symptom: High validation error rate
   - Recovery: Check ffmpeg conversion pipeline
   - Mitigation: Expand supported formats

### TTS Failures
1. **Voice Loading Issues**
   - Symptom: Specific voice models unavailable
   - Recovery: Fallback to default voice, reload models
   - Escalation: Non-critical, can operate with reduced voices

2. **Synthesis Timeouts**
   - Symptom: High latency, timeout errors
   - Recovery: Restart service, check resource constraints
   - Mitigation: Implement request queuing

3. **Audio Generation Artifacts**
   - Symptom: Distorted or corrupted audio output
   - Recovery: Model reload, parameter tuning
   - Investigation: Log problematic inputs for analysis

## Go/No-Go Decision Matrix

| Component | Metric | Threshold | Status | Action if Failed |
|-----------|--------|-----------|---------|------------------|
| ASR Model | Loading | Must load | ⚫ | Block deployment |
| ASR Speed | RT Factor | < 0.5 | ⚫ | Block deployment |
| ASR Accuracy | WER | < 5% | ⚫ | Block deployment |
| TTS Model | Loading | Must load | ⚫ | Block deployment |
| TTS Latency | P95 | < 2s | ⚫ | Block deployment |
| TTS Quality | MOS | > 4.0 | 🟡 | Deploy with warning |
| Multi-lang | Coverage | 5+ langs | 🟡 | Deploy with warning |
| Concurrency | 10 parallel | No crashes | ⚫ | Block deployment |

**Legend**: ⚫ = Hard requirement, 🟡 = Soft requirement

## Rollback Plan

If speech services fail in production:
1. **Immediate**: Route speech requests to fallback text mode
2. **Short-term**: Scale down speech replicas, investigate issues
3. **Recovery**: Rolling restart with known-good models
4. **Communication**: Update status page, notify users of degraded speech features

## Deployment Checklist

- [ ] ASR model files present and validated
- [ ] TTS voice models loaded for primary languages
- [ ] GPU drivers and CUDA toolkit compatible
- [ ] Prometheus metrics exporting correctly
- [ ] Health check endpoints responding
- [ ] Integration tests passing (ASR + TTS)
- [ ] Resource limits configured appropriately
- [ ] Fallback mechanisms tested
- [ ] Monitoring dashboards updated
- [ ] Documentation updated with new endpoints

This gate ensures speech I/O capabilities are production-ready with appropriate quality, performance, and reliability standards.
