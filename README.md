# MoonBit Todo App on Cloudflare Workers

A Todo application built with [MoonBit](https://www.moonbitlang.com/) using Hexagonal Architecture and Always Valid Domain Model, deployed on [Cloudflare Workers](https://workers.cloudflare.com/).

## Architecture

```
          ┌─────────────────────────────────────────┐
          │              Driving Adapter             │
          │         adapter/http/ (HTTP router)      │
          └──────────────┬──────────────────────────┘
                         │
          ┌──────────────▼──────────────────────────┐
          │            Use Cases                     │
          │     usecase/ (application services)      │
          └──────┬──────────────────┬───────────────┘
                 │                  │
  ┌──────────────▼────────┐  ┌─────▼──────────────┐
  │       Domain          │  │      Port           │
  │  domain/ (entities,   │  │  port/ (repository  │
  │  value objects)       │  │  trait)              │
  └───────────────────────┘  └─────┬──────────────┘
                                   │
          ┌────────────────────────▼────────────────┐
          │             Driven Adapter               │
          │    adapter/store/ (InMemoryStore)         │
          └──────────────────────────────────────────┘
```

**Dependencies point inward** — adapters depend on domain/ports, never the reverse.

## Project Structure

```
moonbit-todo-app/
├── domain/                  # Core domain (no infrastructure dependencies)
│   ├── moon.pkg
│   ├── todo.mbt             # Todo, TodoTitle (always valid via smart constructors)
│   └── error.mbt            # DomainError enum
├── port/                    # Port definitions (traits/interfaces)
│   ├── moon.pkg
│   └── repository.mbt       # TodoRepository trait
├── usecase/                 # Application services (orchestrate domain logic)
│   ├── moon.pkg
│   └── todo_usecase.mbt     # create, list, toggle, update, delete
├── adapter/
│   ├── store/               # Driven adapter (infrastructure)
│   │   ├── moon.pkg
│   │   └── memory.mbt       # InMemoryStore implements TodoRepository
│   └── http/                # Driving adapter (HTTP interface)
│       ├── moon.pkg
│       ├── router.mbt       # HTTP routing, JSON conversion
│       └── html.mbt         # HTML/CSS/JS frontend template
├── app/                     # Composition root
│   ├── moon.pkg
│   └── main.mbt             # Wires adapters, exports handle_request
├── worker/
│   └── index.js             # Cloudflare Workers entry point
├── wrangler.toml
└── moon.mod.json
```

## Always Valid Domain Model

- `TodoTitle` — opaque type with `priv` field; can only be created via `TodoTitle::create()` which validates non-empty/non-blank
- `Todo` — all fields are `priv`; constructed only via `Todo::create()`, modified via `toggle()`, `with_title()`, `with_completed()`
- Invalid states are unrepresentable at compile time

## Prerequisites

- [MoonBit toolchain](https://www.moonbitlang.com/download/)
- [Node.js](https://nodejs.org/) (v18+)
- [Wrangler CLI](https://developers.cloudflare.com/workers/wrangler/)

## Development

```bash
moon build --target js --release
wrangler dev
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
