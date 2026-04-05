// Simple JSON body parser - extracts "title" field value
///|
fn parse_title_from_json(body : String) -> String? {
  let key = "\"title\""
  let mut key_idx = -1
  // Find key in body
  for i in 0..<(body.length() - key.length() + 1) {
    let mut found = true
    for j in 0..<key.length() {
      if body[i + j] != key[j] {
        found = false
        break
      }
    }
    if found {
      key_idx = i
      break
    }
  }
  if key_idx < 0 {
    return None
  }
  // Find the colon after "title"
  let after_key = key_idx + key.length()
  let mut colon_idx = after_key
  while colon_idx < body.length() && body[colon_idx] != ':' {
    colon_idx = colon_idx + 1
  }
  if colon_idx >= body.length() {
    return None
  }
  // Find opening quote
  let mut start = colon_idx + 1
  while start < body.length() && body[start] != '"' {
    start = start + 1
  }
  if start >= body.length() {
    return None
  }
  start = start + 1 // skip the opening quote
  // Find closing quote (handle escaped quotes)
  let buf = StringBuilder::new()
  let mut i = start
  while i < body.length() {
    if body[i] == '\\' && i + 1 < body.length() {
      buf.write_string(body[i + 1].to_int().unsafe_to_char().to_string())
      i = i + 2
    } else if body[i] == '"' {
      break
    } else {
      buf.write_string(body[i].to_int().unsafe_to_char().to_string())
      i = i + 1
    }
  }
  Some(buf.to_string())
}

// Parse "completed" field from JSON body

///|
fn parse_completed_from_json(body : String) -> Bool? {
  let key = "\"completed\""
  let mut key_idx = -1
  for i in 0..<(body.length() - key.length() + 1) {
    let mut found = true
    for j in 0..<key.length() {
      if body[i + j] != key[j] {
        found = false
        break
      }
    }
    if found {
      key_idx = i
      break
    }
  }
  if key_idx < 0 {
    return None
  }
  let after_key = key_idx + key.length()
  let mut i = after_key
  // skip whitespace and colon
  while i < body.length() && (body[i] == ' ' || body[i] == ':') {
    i = i + 1
  }
  // Check for "true" or "false"
  if i + 4 <= body.length() {
    let sub = body[i:i + 4].to_string()
    if sub == "true" {
      return Some(true)
    }
  }
  if i + 5 <= body.length() {
    let sub = body[i:i + 5].to_string()
    if sub == "false" {
      return Some(false)
    }
  }
  None
}

// Parse integer from a path segment like "/todos/123"

///|
fn parse_id_from_path(path : String) -> Int? {
  let prefix = "/todos/"
  if !path.has_prefix(prefix) {
    return None
  }
  let rest = path[prefix.length():].to_string()
  let buf = StringBuilder::new()
  for ch in rest {
    if ch >= '0' && ch <= '9' {
      buf.write_char(ch)
    } else {
      break
    }
  }
  let num_str = buf.to_string()
  if num_str.length() == 0 {
    return None
  }
  Some(@string.parse_int(num_str)) catch {
    _ => None
  }
}

// Response structure

///|
struct Response {
  status : Int
  body : String
  content_type : String
}

///|
fn json_response(status : Int, body : String) -> Response {
  { status, body, content_type: "application/json" }
}

///|
fn html_response(status : Int, body : String) -> Response {
  { status, body, content_type: "text/html; charset=utf-8" }
}

// HTML template for the UI

///|
fn render_html() -> String {
  let html =
    #|<!DOCTYPE html>
    #|<html lang="en">
    #|<head>
    #|<meta charset="UTF-8">
    #|<meta name="viewport" content="width=device-width, initial-scale=1.0">
    #|<title>MoonBit Todo App</title>
    #|<style>
    #|  * { margin: 0; padding: 0; box-sizing: border-box; }
    #|  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #f5f5f5; color: #333; min-height: 100vh; display: flex; justify-content: center; padding-top: 60px; }
    #|  .container { width: 100%; max-width: 520px; padding: 0 16px; }
    #|  h1 { text-align: center; font-size: 2rem; color: #e74c3c; margin-bottom: 24px; }
    #|  .input-group { display: flex; gap: 8px; margin-bottom: 24px; }
    #|  .input-group input { flex: 1; padding: 12px 16px; border: 2px solid #ddd; border-radius: 8px; font-size: 1rem; outline: none; transition: border-color 0.2s; }
    #|  .input-group input:focus { border-color: #e74c3c; }
    #|  .input-group button { padding: 12px 24px; background: #e74c3c; color: #fff; border: none; border-radius: 8px; font-size: 1rem; cursor: pointer; transition: background 0.2s; }
    #|  .input-group button:hover { background: #c0392b; }
    #|  .todo-list { list-style: none; }
    #|  .todo-item { display: flex; align-items: center; gap: 12px; padding: 12px 16px; background: #fff; border-radius: 8px; margin-bottom: 8px; box-shadow: 0 1px 3px rgba(0,0,0,0.08); transition: transform 0.1s; }
    #|  .todo-item:hover { transform: translateX(4px); }
    #|  .todo-item.completed .todo-title { text-decoration: line-through; color: #aaa; }
    #|  .todo-title { flex: 1; font-size: 1rem; cursor: pointer; }
    #|  .todo-item input[type="checkbox"] { width: 20px; height: 20px; cursor: pointer; accent-color: #e74c3c; }
    #|  .delete-btn { background: none; border: none; color: #e74c3c; font-size: 1.2rem; cursor: pointer; opacity: 0.5; transition: opacity 0.2s; }
    #|  .delete-btn:hover { opacity: 1; }
    #|  .footer { text-align: center; margin-top: 32px; color: #aaa; font-size: 0.85rem; }
    #|  .empty { text-align: center; color: #aaa; padding: 32px; }
    #|</style>
    #|</head>
    #|<body>
    #|<div class="container">
    #|  <h1>MoonBit Todo</h1>
    #|  <div class="input-group">
    #|    <input type="text" id="todo-input" placeholder="What needs to be done?" onkeydown="if(event.key==='Enter')addTodo()">
    #|    <button onclick="addTodo()">Add</button>
    #|  </div>
    #|  <ul class="todo-list" id="todo-list"></ul>
    #|  <p class="footer">Built with MoonBit + Cloudflare Workers</p>
    #|</div>
    #|<script>
    #|  async function fetchTodos() {
    #|    const res = await fetch('/todos');
    #|    const todos = await res.json();
    #|    renderTodos(todos);
    #|  }
    #|  function renderTodos(todos) {
    #|    const list = document.getElementById('todo-list');
    #|    if (todos.length === 0) {
    #|      list.innerHTML = '<li class="empty">No todos yet. Add one above!</li>';
    #|      return;
    #|    }
    #|    list.innerHTML = todos.map(t => `
    #|      <li class="todo-item ${t.completed ? 'completed' : ''}">
    #|        <input type="checkbox" ${t.completed ? 'checked' : ''} onchange="toggleTodo(${t.id})">
    #|        <span class="todo-title">${escapeHtml(t.title)}</span>
    #|        <button class="delete-btn" onclick="deleteTodo(${t.id})">&#x2715;</button>
    #|      </li>
    #|    `).join('');
    #|  }
    #|  function escapeHtml(s) {
    #|    return s.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
    #|  }
    #|  async function addTodo() {
    #|    const input = document.getElementById('todo-input');
    #|    const title = input.value.trim();
    #|    if (!title) return;
    #|    await fetch('/todos', { method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify({title}) });
    #|    input.value = '';
    #|    fetchTodos();
    #|  }
    #|  async function toggleTodo(id) {
    #|    await fetch('/todos/' + id + '/toggle', { method: 'PUT' });
    #|    fetchTodos();
    #|  }
    #|  async function deleteTodo(id) {
    #|    await fetch('/todos/' + id, { method: 'DELETE' });
    #|    fetchTodos();
    #|  }
    #|  fetchTodos();
    #|</script>
    #|</body>
    #|</html>
  html
}

///|
fn main {
  // Entry point required by MoonBit for main packages
  // Actual logic is driven by handle_request called from JS
}

///|
/// The main request handler exported to JavaScript
/// Returns a JSON string: {"status": N, "body": "...", "content_type": "..."}
pub fn handle_request(
  req_method : String,
  path : String,
  body : String,
) -> String {
  let resp = route(req_method, path, body)
  let escaped_body = escape_json_string(resp.body)
  let escaped_ct = escape_json_string(resp.content_type)
  "{\"status\":\{resp.status},\"body\":\"\{escaped_body}\",\"content_type\":\"\{escaped_ct}\"}"
}

///|
fn route(req_method : String, path : String, body : String) -> Response {
  // Serve HTML UI at root
  if path == "/" && req_method == "GET" {
    return html_response(200, render_html())
  }
  // GET /todos - list all todos
  if path == "/todos" && req_method == "GET" {
    return json_response(200, todos_to_json(get_all_todos()))
  }
  // POST /todos - create a new todo
  if path == "/todos" && req_method == "POST" {
    match parse_title_from_json(body) {
      Some(title) => {
        if title.length() == 0 {
          return json_response(400, "{\"error\":\"title is required\"}")
        }
        let todo = add_todo(title)
        return json_response(201, todo_to_json(todo))
      }
      None => return json_response(400, "{\"error\":\"title is required\"}")
    }
  }
  // PUT /todos/:id/toggle - toggle completion
  if path.has_prefix("/todos/") &&
    path.has_suffix("/toggle") &&
    req_method == "PUT" {
    let without_toggle = path[:path.length() - "/toggle".length()].to_string()
    match parse_id_from_path(without_toggle) {
      Some(id) =>
        match toggle_todo(id) {
          Some(todo) => return json_response(200, todo_to_json(todo))
          None => return json_response(404, "{\"error\":\"todo not found\"}")
        }
      None => return json_response(400, "{\"error\":\"invalid id\"}")
    }
  }
  // PUT /todos/:id - update a todo
  if path.has_prefix("/todos/") && req_method == "PUT" {
    match parse_id_from_path(path) {
      Some(id) => {
        let title = parse_title_from_json(body)
        let completed = parse_completed_from_json(body)
        match title {
          Some(t) => update_todo_title(id, t) |> ignore
          None => ()
        }
        match completed {
          Some(c) =>
            for i in 0..<todos.length() {
              if todos[i].id == id {
                let old = todos[i]
                todos[i] = { id: old.id, title: old.title, completed: c }
              }
            }
          None => ()
        }
        match get_todo(id) {
          Some(todo) => return json_response(200, todo_to_json(todo))
          None => return json_response(404, "{\"error\":\"todo not found\"}")
        }
      }
      None => return json_response(400, "{\"error\":\"invalid id\"}")
    }
  }
  // DELETE /todos/:id - delete a todo
  if path.has_prefix("/todos/") && req_method == "DELETE" {
    match parse_id_from_path(path) {
      Some(id) =>
        if delete_todo(id) {
          return json_response(200, "{\"deleted\":true}")
        } else {
          return json_response(404, "{\"error\":\"todo not found\"}")
        }
      None => return json_response(400, "{\"error\":\"invalid id\"}")
    }
  }
  // 404 for everything else
  json_response(404, "{\"error\":\"not found\"}")
}
