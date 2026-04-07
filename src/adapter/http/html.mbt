// HTML template for the Todo UI (separated for clarity)

///|
fn render_html() -> String {
  (
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
  )
}
