# Runbook — Speech I/O Ingest
1) Preflight: confirm sandbox types (.wav/.mp3/.ogg), <= 50MB; region routing.
2) ASR:
   - Model: faster-whisper (size small/medium), device=auto.
   - Streaming: 20–40ms frames, 50% overlap.
   - Fallback: CPU tiny/base on OOM; reduce beam size to 1; disable vad if unstable.
3) Optional: Alignment (whisperX) & diarization (NeMo).
4) TTS:
   - Piper voice = en_US/*; speed 0.9–1.1; output WAV 16kHz mono.
5) Store: transcript JSON + timings → DB-as-memory; redact PII if policy==strict.
6) Troubleshooting:
   - High RTF → lower model size; enable quantization; batch=1.
   - Slow TTFB → pre-warm voices; cache text norm.
7) Close: append DECISIONS.log with action and metrics snapshot.
