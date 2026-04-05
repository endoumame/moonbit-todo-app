# MoonBit Todo App on Cloudflare Workers

A simple Todo application built with [MoonBit](https://www.moonbitlang.com/) and deployed on [Cloudflare Workers](https://workers.cloudflare.com/).

MoonBit code is compiled to JavaScript via `moon build --target js` and served through a Cloudflare Workers entry point.

## Project Structure

```
moonbit-todo-app/
├── moon.mod.json              # MoonBit module configuration
├── src/
│   └── lib/
│       ├── moon.pkg.json      # Package config (exports, JS format)
│       ├── todo.mbt           # Todo data model and CRUD operations
│       └── handler.mbt        # HTTP routing and HTML UI
├── worker/
│   └── index.js               # Cloudflare Workers entry point
├── wrangler.toml              # Cloudflare Workers configuration
└── .gitignore
```

## Prerequisites

- [MoonBit toolchain](https://www.moonbitlang.com/download/) (`moon` and `moonc`)
- [Node.js](https://nodejs.org/) (v18+)
- [Wrangler CLI](https://developers.cloudflare.com/workers/wrangler/) (`npm install -g wrangler`)

## Development

```bash
# Build MoonBit to JS
moon build --target js --release

# Run locally
wrangler dev

# Deploy to Cloudflare Workers
wrangler deploy
```

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | HTML UI |
| GET | `/todos` | List all todos |
| POST | `/todos` | Create a todo (`{"title": "..."}`) |
| PUT | `/todos/:id/toggle` | Toggle completion |
| PUT | `/todos/:id` | Update a todo |
| DELETE | `/todos/:id` | Delete a todo |
