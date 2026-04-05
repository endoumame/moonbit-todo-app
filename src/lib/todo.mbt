// Todo item structure
///|
struct Todo {
  id : Int
  title : String
  completed : Bool
} derive(Show)

// Global mutable state for todos (in-memory storage)

///|
let todos : Array[Todo] = []

///|
let next_id : Ref[Int] = { val: 1 }

///|
fn add_todo(title : String) -> Todo {
  let todo : Todo = { id: next_id.val, title, completed: false }
  next_id.val = next_id.val + 1
  todos.push(todo)
  todo
}

///|
fn get_all_todos() -> Array[Todo] {
  todos
}

///|
fn get_todo(id : Int) -> Todo? {
  for todo in todos {
    if todo.id == id {
      return Some(todo)
    }
  }
  None
}

///|
fn toggle_todo(id : Int) -> Todo? {
  for i in 0..<todos.length() {
    if todos[i].id == id {
      let old = todos[i]
      let updated : Todo = {
        id: old.id,
        title: old.title,
        completed: !old.completed,
      }
      todos[i] = updated
      return Some(updated)
    }
  }
  None
}

///|
fn update_todo_title(id : Int, title : String) -> Todo? {
  for i in 0..<todos.length() {
    if todos[i].id == id {
      let old = todos[i]
      let updated : Todo = { id: old.id, title, completed: old.completed }
      todos[i] = updated
      return Some(updated)
    }
  }
  None
}

///|
fn delete_todo(id : Int) -> Bool {
  for i in 0..<todos.length() {
    if todos[i].id == id {
      todos.remove(i) |> ignore
      return true
    }
  }
  false
}

///|
fn todo_to_json(todo : Todo) -> String {
  let completed_str = if todo.completed { "true" } else { "false" }
  let escaped_title = escape_json_string(todo.title)
  "{\"id\":\{todo.id},\"title\":\"\{escaped_title}\",\"completed\":\{completed_str}}"
}

///|
fn todos_to_json(arr : Array[Todo]) -> String {
  let buf = StringBuilder::new()
  buf.write_char('[')
  for i, todo in arr {
    if i > 0 {
      buf.write_char(',')
    }
    buf.write_string(todo_to_json(todo))
  }
  buf.write_char(']')
  buf.to_string()
}

///|
fn escape_json_string(s : String) -> String {
  let buf = StringBuilder::new()
  for ch in s {
    match ch {
      '"' => buf.write_string("\\\"")
      '\\' => buf.write_string("\\\\")
      '\n' => buf.write_string("\\n")
      '\r' => buf.write_string("\\r")
      '\t' => buf.write_string("\\t")
      _ => buf.write_char(ch)
    }
  }
  buf.to_string()
}
