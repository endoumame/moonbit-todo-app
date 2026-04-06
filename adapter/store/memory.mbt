// Driven adapter — in-memory implementation of TodoRepository.
// Infrastructure concern: mutable state lives here, not in the domain.

///|
struct StoreState {
  todos : @sorted_map.SortedMap[Int, @domain.Todo]
  next_id : Int
}

///|
pub struct InMemoryStore {
  state : Ref[StoreState]
}

///|
pub fn InMemoryStore::new() -> InMemoryStore {
  { state: { val: { todos: @sorted_map.SortedMap::new(), next_id: 1 } } }
}

///|
pub impl @port.TodoRepository for InMemoryStore with find_all(self) -> Array[
  @domain.Todo,
] {
  self.state.val.todos.iter().map(fn(pair) { pair.1 }).collect()
}

///|
pub impl @port.TodoRepository for InMemoryStore with find_by_id(self, id) -> @domain.Todo? {
  self.state.val.todos.get(id)
}

///|
pub impl @port.TodoRepository for InMemoryStore with save(self, todo) -> Unit {
  self.state.val = {
    ..self.state.val,
    todos: self.state.val.todos.add(todo.id(), todo),
  }
}

///|
pub impl @port.TodoRepository for InMemoryStore with remove(self, id) -> Bool {
  if self.state.val.todos.contains(id) {
    self.state.val = {
      ..self.state.val,
      todos: self.state.val.todos.remove(id),
    }
    true
  } else {
    false
  }
}

///|
pub impl @port.TodoRepository for InMemoryStore with next_id(self) -> Int {
  let id = self.state.val.next_id
  self.state.val = { ..self.state.val, next_id: id + 1 }
  id
}
