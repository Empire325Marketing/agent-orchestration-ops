# CH37: Speech I/O Integration (DW-03)

## Overview

Speech I/O capabilities for Primarch agents, providing bi-directional voice interaction through high-quality ASR (Automatic Speech Recognition) and TTS (Text-to-Speech) services.

## Design Goals

- **Low Latency**: < 500ms for TTS, < 2s for ASR
- **High Quality**: WER < 5% for clean audio, natural-sounding TTS
- **Privacy-First**: On-premises processing, no cloud dependencies
- **Multi-Language**: Support for 10+ languages
- **Integration**: Seamless tool adapter integration

## Architecture

### ASR Pipeline (Faster Whisper)

```
Audio Input → Preprocessing → Faster Whisper → Post-processing → Text Output
     ↓            ↓              ↓              ↓              ↓
  Format      Normalize     Transcribe     Clean/Filter    Structured
 Detection    Audio Levels    Speech         Text           Response
```

### TTS Pipeline (Piper)

```
Text Input → Text Analysis → Piper TTS → Audio Processing → Audio Output
     ↓           ↓             ↓            ↓               ↓
  Language    Phonemize    Synthesize    Normalize       Format
 Detection   & Tokenize     Speech       Audio           Response
```

## Component Specifications

### ASR Service (Faster Whisper)

**Model Configuration:**
- Model: `faster-whisper-large-v2`
- Compute: CUDA (RTX 5090) with CPU fallback
- Memory: 4GB VRAM allocated
- Context Length: 30-second chunks with overlap

**Input Specifications:**
```yaml
audio_formats: [wav, mp3, m4a, flac, ogg]
sample_rates: [16000, 22050, 44100, 48000]  # Auto-resample to 16kHz
channels: [mono, stereo]  # Convert stereo to mono
max_duration: 300  # seconds
max_file_size: 25  # MB
```

**Output Format:**
```json
{
  "transcript": "The transcribed text content",
  "language": "en",
  "confidence": 0.95,
  "segments": [
    {
      "text": "segment text",
      "start": 0.0,
      "end": 2.5,
      "confidence": 0.98
    }
  ],
  "processing_time_ms": 1250,
  "model_used": "faster-whisper-large-v2"
}
```

### TTS Service (Piper)

**Voice Configuration:**
```yaml
voices:
  en_US:
    - lessac-medium (default)
    - ryan-medium
    - amy-medium
  en_GB:
    - alba-medium
    - northern_english_male-medium
  es_ES:
    - carlfm-x-low
  fr_FR:
    - upmc-medium
  de_DE:
    - thorsten-medium
```

**Input Specifications:**
```yaml
text_length: 
  min: 1
  max: 2000  # characters
formats: [text/plain, application/json]
languages: [en, es, fr, de, it, pt, nl, pl, ru, zh]
```

**Output Format:**
```json
{
  "audio_url": "/tmp/tts_output_uuid.wav",
  "duration_ms": 3500,
  "sample_rate": 22050,
  "format": "wav",
  "voice_used": "en_US-lessac-medium",
  "processing_time_ms": 800,
  "text_length": 42
}
```

## Tool Specifications

### ASR Tool Spec (asr_faster_whisper)

```json
{
  "name": "asr_faster_whisper",
  "description": "Convert speech audio to text using Faster Whisper",
  "type": "asr",
  "version": "1.0.0",
  "required_permission": "user",
  "parameters": {
    "audio_data": {
      "type": "binary",
      "required": true,
      "description": "Audio file data (WAV, MP3, M4A, FLAC, OGG)"
    },
    "language": {
      "type": "string",
      "required": false,
      "default": "auto",
      "description": "Language code (auto-detect if not specified)"
    },
    "task": {
      "type": "string",
      "required": false,
      "default": "transcribe",
      "enum": ["transcribe", "translate"],
      "description": "Task type: transcribe or translate to English"
    }
  },
  "timeout": 60,
  "rate_limits": {
    "per_minute": 10,
    "per_hour": 100
  },
  "resource_requirements": {
    "memory_mb": 4096,
    "gpu_memory_mb": 4096,
    "cpu_cores": 2
  }
}
```

### TTS Tool Spec (tts_piper)

```json
{
  "name": "tts_piper",
  "description": "Convert text to natural speech using Piper TTS",
  "type": "tts",
  "version": "1.0.0",
  "required_permission": "user",
  "parameters": {
    "text": {
      "type": "string",
      "required": true,
      "max_length": 2000,
      "description": "Text to convert to speech"
    },
    "voice": {
      "type": "string",
      "required": false,
      "default": "en_US-lessac-medium",
      "description": "Voice model to use"
    },
    "speed": {
      "type": "number",
      "required": false,
      "default": 1.0,
      "min": 0.5,
      "max": 2.0,
      "description": "Speech speed multiplier"
    },
    "output_format": {
      "type": "string",
      "required": false,
      "default": "wav",
      "enum": ["wav", "mp3"],
      "description": "Audio output format"
    }
  },
  "timeout": 30,
  "rate_limits": {
    "per_minute": 30,
    "per_hour": 500
  },
  "resource_requirements": {
    "memory_mb": 2048,
    "cpu_cores": 2
  }
}
```

## Implementation Details

### Model Management

**ASR Model Setup:**
```bash
# Download Faster Whisper model
mkdir -p /srv/primarch/models/faster-whisper
cd /srv/primarch/models/faster-whisper
wget https://huggingface.co/guillaumekln/faster-whisper-large-v2/resolve/main/config.json
wget https://huggingface.co/guillaumekln/faster-whisper-large-v2/resolve/main/model.bin
```

**TTS Model Setup:**
```bash
# Download Piper voices
mkdir -p /srv/primarch/models/piper-voices
cd /srv/primarch/models/piper-voices

# English voices
wget https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx
wget https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx.json

# Additional language models as needed
```

### Service Configuration

**docker-compose.yml Integration:**
```yaml
services:
  speech-asr:
    image: primarch/faster-whisper:latest
    volumes:
      - ./models/faster-whisper:/models:ro
      - speech-temp:/tmp
    environment:
      - CUDA_VISIBLE_DEVICES=0
      - MODEL_PATH=/models
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]

  speech-tts:
    image: primarch/piper-tts:latest
    volumes:
      - ./models/piper-voices:/voices:ro
      - speech-temp:/tmp
    environment:
      - VOICES_PATH=/voices
      - DEFAULT_VOICE=en_US-lessac-medium

  speech-gateway:
    image: kong:3.4
    environment:
      - KONG_DATABASE=off
      - KONG_DECLARATIVE_CONFIG=/config/kong.yml
    volumes:
      - ./config/speech-kong.yml:/config/kong.yml:ro
```

### Error Handling

**Common Error Scenarios:**
1. **Audio Format Issues**: Auto-conversion with ffmpeg
2. **Model Loading Failures**: Graceful degradation to CPU
3. **CUDA OOM**: Dynamic batch sizing
4. **Network Timeouts**: Retry with exponential backoff

**Error Response Format:**
```json
{
  "success": false,
  "error": {
    "type": "audio_format_error",
    "message": "Unsupported audio format",
    "code": "SPEECH_E001",
    "details": {
      "supported_formats": ["wav", "mp3", "m4a", "flac", "ogg"],
      "received_format": "aac"
    }
  },
  "processing_time_ms": 50
}
```

## Performance Benchmarks

### ASR Performance Targets

| Audio Duration | Target Latency | Max Latency | WER Target |
|---------------|----------------|-------------|------------|
| < 10s         | < 1s          | < 2s        | < 3%       |
| 10-30s        | < 2s          | < 5s        | < 5%       |
| 30-60s        | < 5s          | < 10s       | < 5%       |

### TTS Performance Targets

| Text Length | Target Latency | Max Latency | MOS Score |
|-------------|----------------|-------------|-----------|
| < 50 chars  | < 300ms       | < 500ms     | > 4.0     |
| 50-200 chars| < 500ms       | < 1s        | > 4.0     |
| 200+ chars  | < 1s          | < 2s        | > 3.8     |

### Resource Utilization

**ASR (Faster Whisper):**
- GPU Memory: ~3GB (large-v2 model)
- System Memory: ~2GB
- CPU: 2-4 cores during processing

**TTS (Piper):**
- GPU Memory: Not required
- System Memory: ~1GB
- CPU: 1-2 cores during synthesis

## Quality Assurance

### Testing Strategy

**ASR Testing:**
1. **Clean Audio**: Professional recordings, WER < 3%
2. **Noisy Audio**: Background noise, WER < 8%
3. **Accented Speech**: Various accents, WER < 10%
4. **Multiple Languages**: Core languages, WER < 5%

**TTS Testing:**
1. **Naturalness**: MOS > 4.0 for primary voices
2. **Intelligibility**: 100% word accuracy
3. **Pronunciation**: Proper nouns and technical terms
4. **Speed Variation**: 0.5x to 2.0x speed range

### Monitoring & Alerts

**Key Metrics:**
- Processing latency (p95, p99)
- Error rates by error type
- Model loading success rates
- Resource utilization trends

**Alert Thresholds:**
- ASR latency > 5s (P95)
- TTS latency > 2s (P95)
- Error rate > 5%
- GPU memory usage > 90%

## Security & Privacy

### Data Handling

1. **Audio Privacy**: No audio stored permanently
2. **Temporary Files**: Auto-cleanup after 1 hour
3. **Logs**: No sensitive content in logs
4. **Encryption**: TLS 1.3 for all endpoints

### Access Control

1. **Rate Limiting**: Per-tenant limits enforced
2. **Authentication**: Bearer token required
3. **Authorization**: RBAC integration
4. **Audit**: All speech requests logged

This specification ensures high-quality, performant, and secure speech I/O capabilities for Primarch agents with full integration into the tool adapter framework.
