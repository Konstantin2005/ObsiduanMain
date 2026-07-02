# Frontend Engineer: Background People Links Generation

## UI
- [x] **People Links Panel** - Main UI component with loading/error states
- [x] **Progress Indicator** - Shows generation progress
- [x] **Empty State** - When no links are available
- [x] **Error State** - When generation fails

## Компоненты
- [x] `PeopleLinksPanel` - Container component
- [x] `PeopleLinkNode` - Individual node component
- [x] `PeopleLinkEdge` - Connection visualization

## Состояние
- [x] **Loading** - During initial load and generation
- [x] **Empty** - Cache miss without generation
- [x] **Progress** - Background generation in progress
- [x] **Ready** - Links generated and cached
- [x] **Error** - Generation or API failed

## Файлы
- [x] `src/components/PeopleLinksPanel.tsx` - Main UI component
- [x] `src/components/PeopleLinkNode.tsx` - Node visualization
- [x] `src/components/PeopleLinkEdge.tsx` - Edge visualization
- [x] `src/hooks/usePeopleLinks.tsx` - Custom hook for API integration
- [x] `src/hooks/useGenerationStatus.tsx` - Hook for tracking generation status
- [x] `src/services/api.ts` - API client
- [x] `package.json` - Project configuration

## Проектная структура
```
02-frontend-engineer/
├── src/
│   ├── components/
│   │   ├── PeopleLinksPanel.tsx
│   │   ├── PeopleLinkNode.tsx
│   │   └── PeopleLinkEdge.tsx
│   ├── hooks/
│   │   ├── usePeopleLinks.tsx
│   │   └── useGenerationStatus.tsx
│   ├── services/
│   │   └── api.ts
│   └── types/
│       └── people-links.tsx
└── package.json
```

## API Integration
- `GET /api/people-links` - Get cached links or trigger generation
- `GET /api/people-links/status/{taskId}` - Check generation status
- WebSocket connection for real-time generation updates
