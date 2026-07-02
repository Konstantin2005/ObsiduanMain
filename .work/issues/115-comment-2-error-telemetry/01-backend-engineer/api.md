# Error Telemetry API

## ErrorLogger (singleton)
```
ErrorLogger.init({ repoDir, bufferSize, flushInterval }) → instance
ErrorLogger.getInstance() → instance | null

instance.capture(error, source, severity)
instance.wrap(asyncFn, source) → wrappedFn
instance.handler(source) → (err) => void
instance.flush()
instance.dispose()
```

## ErrorCollector
```
new ErrorCollector({ maxSize, flushInterval, transport, fallback })
collector.capture(error, source, severity)
collector.flush()
collector.start()
collector.stop()
collector.pending  → number
```

## GitTransport
```
new GitTransport({ repoDir, retries, retryDelay })
transport.write(batch) → Promise<void>
```

## FallbackStorage
```
new FallbackStorage({ dir })
storage.write(batch) → Promise<void>
```

## Hooks
```
createAgentTelemetry(agent, errorLogger) → agent (mutated)
createPipelineTelemetry(pipeline, errorLogger) → pipeline (mutated)
createTemplateTelemetry(engine, errorLogger) → engine (mutated)
```
