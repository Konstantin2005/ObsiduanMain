# Backend Engineer: Background People Links Generation

## API
- [x] `GET /api/people-links` - Get cached people links or trigger generation
- [x] `POST /api/people-links/generate` - Trigger immediate background generation
- [x] `DELETE /api/people-links` - Invalidate cache and trigger re-generation
- [x] `GET /api/people-links/status/{taskId}` - Check generation status
- [x] `GET /api/people-links/health` - Health check for background worker

## Реализация
- [x] **PeopleLinkService** - Core business logic for link generation
- [x] **PeopleLinkCache** - Redis/IndexedDB caching layer
- [x] **BackgroundWorkerPool** - Worker thread management
- [x] **LinkGenerationTaskManager** - Task lifecycle and queue management
- [x] **PeopleLinkRepository** - Data access for people and relationships
- [x] **CacheInvalidationService** - Invalidation on vault changes

## Файлы
- [x] `src/types/people-links.ts` - Type definitions
- [ ] `src/services/PeopleLinkService.ts` - Business logic
- [ ] `src/cache/PeopleLinkCache.ts` - Cache implementation
- [ ] `src/workers/BackgroundWorker.ts` - Worker thread management
- [ ] `src/api/peopleLinksController.ts` - Express API endpoints
- [ ] `src/tasks/LinkGenerationTaskManager.ts` - Task orchestration
- [ ] `src/observers/CacheInvalidationObserver.ts` - Observer pattern for invalidation
- [ ] `package.json` - Project configuration and dependencies
