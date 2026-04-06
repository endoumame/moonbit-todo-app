///|
test "TodoTitle::create rejects empty string" {
  assert_true(TodoTitle::create("") is Err(EmptyTitle))
}

///|
test "TodoTitle::create rejects whitespace-only" {
  assert_true(TodoTitle::create("   ") is Err(EmptyTitle))
}

///|
test "TodoTitle::create trims and accepts valid title" {
  let title = TodoTitle::create("  Buy milk  ") |> Result::unwrap
  assert_eq(title.to_string(), "Buy milk")
}

///|
test "Todo::create sets completed to false" {
  let title = TodoTitle::create("test") |> Result::unwrap
  let todo = Todo::create(1, title)
  assert_eq(todo.id(), 1)
  assert_eq(todo.completed(), false)
}

///|
test "Todo::toggle flips completed" {
  let title = TodoTitle::create("test") |> Result::unwrap
  let todo = Todo::create(1, title)
  assert_eq(todo.toggle().completed(), true)
  assert_eq(todo.toggle().toggle().completed(), false)
}

///|
test "Todo::with_title preserves other fields" {
  let title1 = TodoTitle::create("first") |> Result::unwrap
  let title2 = TodoTitle::create("second") |> Result::unwrap
  let todo = Todo::create(1, title1).toggle()
  let updated = todo.with_title(title2)
  assert_eq(updated.id(), 1)
  assert_eq(updated.title().to_string(), "second")
  assert_eq(updated.completed(), true)
}

///|
test "Todo::to_json produces correct structure" {
  let title = TodoTitle::create("test") |> Result::unwrap
  let todo = Todo::create(42, title)
  let json_str = todo.to_json().stringify()
  assert_true(json_str.contains("\"id\":42"))
  assert_true(json_str.contains("\"title\":\"test\""))
  assert_true(json_str.contains("\"completed\":false"))
}

///|
test "Todo::apply_update with title only" {
  let title = TodoTitle::create("old") |> Result::unwrap
  let todo = Todo::create(1, title)
  let updated = todo.apply_update(Some("new"), None) |> Result::unwrap
  assert_eq(updated.title().to_string(), "new")
  assert_eq(updated.completed(), false)
}

///|
test "Todo::apply_update with completed only" {
  let title = TodoTitle::create("task") |> Result::unwrap
  let todo = Todo::create(1, title)
  let updated = todo.apply_update(None, Some(true)) |> Result::unwrap
  assert_eq(updated.title().to_string(), "task")
  assert_eq(updated.completed(), true)
}

///|
test "Todo::apply_update rejects empty title" {
  let title = TodoTitle::create("ok") |> Result::unwrap
  let todo = Todo::create(1, title)
  assert_true(todo.apply_update(Some(""), None) is Err(EmptyTitle))
}
