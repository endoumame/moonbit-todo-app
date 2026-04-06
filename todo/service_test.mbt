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
  let (todo, events) = create(repo, "Buy milk") |> Result::unwrap
  assert_eq(todo.title().to_string(), "Buy milk")
  assert_eq(list(repo).length(), 1)
  assert_eq(events.length(), 1)
  assert_true(events[0] is TodoCreated(_))
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
  let (todo, _) = create(repo, "task") |> Result::unwrap
  let (toggled, events) = toggle(repo, todo.id()) |> Result::unwrap
  assert_eq(toggled.completed(), true)
  assert_true(events[0] is TodoToggled(_))
}

///|
test "toggle non-existent returns TodoNotFound" {
  let repo = TestRepo::new()
  assert_true(toggle(repo, 999) is Err(TodoNotFound(_)))
}

///|
test "update title" {
  let repo = TestRepo::new()
  let (todo, _) = create(repo, "old") |> Result::unwrap
  let (updated, events) = update(repo, todo.id(), Some("new"), None)
    |> Result::unwrap
  assert_eq(updated.title().to_string(), "new")
  assert_true(events[0] is TodoUpdated(_))
}

///|
test "update with empty title fails" {
  let repo = TestRepo::new()
  let (todo, _) = create(repo, "ok") |> Result::unwrap
  assert_true(update(repo, todo.id(), Some(""), None) is Err(EmptyTitle))
}

///|
test "delete removes todo" {
  let repo = TestRepo::new()
  let (todo, _) = create(repo, "del") |> Result::unwrap
  let events = delete(repo, todo.id()) |> Result::unwrap
  assert_eq(list(repo).length(), 0)
  assert_true(events[0] is TodoDeleted(_))
}

///|
test "delete non-existent returns error" {
  let repo = TestRepo::new()
  assert_true(delete(repo, 42) is Err(TodoNotFound(_)))
}
