# MoonBit Todo App on Cloudflare Workers

A Todo application built with [MoonBit](https://www.moonbitlang.com/), deployed on [Cloudflare Workers](https://workers.cloudflare.com/).

Domain-concept packaging (DDD Module Pattern) + Always Valid Domain Model + Hexagonal Architecture.

## Architecture

```
  ┌──────────────────────────────┐
  │       Driving Adapter        │
  │  adapter/http/ (HTTP router) │
  └────────────┬─────────────────┘
               │ calls
  ┌────────────▼─────────────────┐
  │         todo/                │
  │  Entity, Value Objects,      │
  │  Repository Trait, Services  │
  └────────────┬─────────────────┘
               │ implemented by
  ┌────────────▼─────────────────┐
  │       Driven Adapter         │
  │  adapter/store/ (InMemory)   │
  └──────────────────────────────┘
```

Adapters depend on `todo/`, never the reverse.

## Project Structure

```
moonbit-todo-app/
├── todo/                        # Domain concept (DDD module)
│   ├── entity.mbt              # Todo, TodoTitle (always valid)
│   ├── error.mbt               # DomainError
│   ├── repository.mbt          # TodoRepository trait
│   ├── service.mbt             # create, list, toggle, update, delete
│   ├── entity_test.mbt         # Value object / entity tests
│   └── service_test.mbt        # Service tests with TestRepo
├── adapter/
│   ├── store/
│   │   └── memory.mbt          # InMemoryStore implements TodoRepository
│   └── http/
│       ├── router.mbt          # HTTP routing, JSON ↔ domain translation
│       └── html.mbt            # HTML/CSS/JS frontend
├── app/
│   └── main.mbt                # Composition root, exports handle_request
├── worker/
│   └── index.js                # Cloudflare Workers entry point
├── wrangler.toml
└── moon.mod.json
```

## Always Valid Domain Model

- **`TodoTitle`** — `priv` field, smart constructor `TodoTitle::create()` rejects empty/whitespace-only
- **`Todo`** — all fields `priv`, constructed via `Todo::create()`, immutable updates via `toggle()`, `with_title()`, `with_completed()`
- Invalid states are unrepresentable

## Prerequisites

- [MoonBit toolchain](https://www.moonbitlang.com/download/)
- [Node.js](https://nodejs.org/) (v18+)
- [Wrangler CLI](https://developers.cloudflare.com/workers/wrangler/)

## Development

```bash
# Build
moon build --target js --release

# Test (15 unit tests)
moon test --target js

# Run locally
wrangler dev

# Deploy
wrangler deploy
```

## API

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | HTML UI |
| GET | `/todos` | List all todos |
| POST | `/todos` | Create (`{"title": "..."}`) |
| PUT | `/todos/:id/toggle` | Toggle completion |
| PUT | `/todos/:id` | Update fields |
| DELETE | `/todos/:id` | Delete |
