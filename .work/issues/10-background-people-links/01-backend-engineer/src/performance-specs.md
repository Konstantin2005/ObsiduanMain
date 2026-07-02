The key characteristics of people link generation:

1. **Foreground Performance**: Initial graph load must complete in < 500ms
2. **Background Processing**: Link generation should not block UI
3. **Cache Efficiency**: Hit rate > 90% for repeated vault loads
4. **Update Behavior**: Debounce re-generation for 2s after changes
5. **Scalability**: Handle 20k+ people links efficiently
6. **Reliability**: Graceful degradation on worker failure

## Performance Expectations
- First load (cold cache): 0.5s + background generation
- Subsequent loads (warm cache): < 50ms
- Re-generation after edits: Triggered within 200ms
- Concurrent generation: Support 3 parallel workers

## Edge Cases
- Empty vault (no people notes)
- All notes edited simultaneously
- Corrupted cache data
- Worker process termination
- Network issues (offline mode)

## Success Criteria
1. Foreground graph load completes in < 500ms
2. Links appear within 2s of vault load
3. Cache hit rate > 90%
4. No UI blocking during generation
5. Consistent behavior across different vault sizes