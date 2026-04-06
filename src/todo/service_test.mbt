// Test with a trivial in-process repository (no external deps)

///|
priv struct TodoEntry {
  id : Int
  todo : Todo
}

///|
priv struct RepoState {
  todos : Array[TodoEntry]
  next : Int
}

///|
priv struct TestRepo {
  state : Ref[RepoState]
}

///|
fn TestRepo::new() -> TestRepo {
  { state: { val: { todos: [], next: 1 } } }
}

///|
impl TodoRepository for TestRepo with find_all(self) -> Array[Todo] {
  self.state.val.todos.map(fn(e) { e.todo })
}

///|
impl TodoRepository for TestRepo with find_by_id(self, id) -> Todo? {
  self.state.val.todos
  .iter()
  .find_first(fn(e) { e.id == id })
  .map(fn(e) { e.todo })
}

///|
impl TodoRepository for TestRepo with save(self, todo) -> Unit {
  let filtered = self.state.val.todos.filter(fn(e) { e.id != todo.id() })
  filtered.push({ id: todo.id(), todo })
  self.state.val = { ..self.state.val, todos: filtered }
}

///|
impl TodoRepository for TestRepo with remove(self, id) -> Bool {
  let before = self.state.val.todos.length()
  let filtered = self.state.val.todos.filter(fn(e) { e.id != id })
  self.state.val = { ..self.state.val, todos: filtered }
  filtered.length() < before
}

///|
impl TodoRepository for TestRepo with next_id(self) -> Int {
  let id = self.state.val.next
  self.state.val = { ..self.state.val, next: id + 1 }
  id
}

///|
test "create and list" {
  let repo = TestRepo::new()
  let todo = create(repo, "Buy milk") |> Result::unwrap
  assert_eq(todo.title().to_string(), "Buy milk")
  assert_eq(list(repo).length(), 1)
}

///|
test "create rejects empty title" {
  let repo = TestRepo::new()
  assert_true(create(repo, "") is Err(EmptyTitle))
  assert_eq(list(repo).length(), 0)
}

///|
test "toggle flips completed via service" {
  let repo = TestRepo::new()
  let todo = create(repo, "task") |> Result::unwrap
  let toggled = toggle(repo, todo.id()) |> Result::unwrap
  assert_eq(toggled.completed(), true)
}

///|
test "toggle non-existent returns TodoNotFound" {
  let repo = TestRepo::new()
  assert_true(toggle(repo, 999) is Err(TodoNotFound(_)))
}

///|
test "update title" {
  let repo = TestRepo::new()
  let todo = create(repo, "old") |> Result::unwrap
  let updated = update(repo, todo.id(), Some("new"), None) |> Result::unwrap
  assert_eq(updated.title().to_string(), "new")
}

///|
test "update with empty title fails" {
  let repo = TestRepo::new()
  let todo = create(repo, "ok") |> Result::unwrap
  assert_true(update(repo, todo.id(), Some(""), None) is Err(EmptyTitle))
}

///|
test "delete removes todo" {
  let repo = TestRepo::new()
  let todo = create(repo, "del") |> Result::unwrap
  assert_true(delete(repo, todo.id()) is Ok(_))
  assert_eq(list(repo).length(), 0)
}

///|
test "delete non-existent returns error" {
  let repo = TestRepo::new()
  assert_true(delete(repo, 42) is Err(TodoNotFound(_)))
}
