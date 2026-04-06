// Driven adapter — in-memory TodoRepository implementation.

///|
priv struct StoreState {
  todos : @sorted_map.SortedMap[Int, @todo.Todo]
  next_id : Int
}

///|
pub struct InMemoryStore {
  priv state : Ref[StoreState]
}

///|
pub fn InMemoryStore::new() -> InMemoryStore {
  { state: { val: { todos: @sorted_map.SortedMap::new(), next_id: 1 } } }
}

///|
pub impl @todo.TodoRepository for InMemoryStore with find_all(self) -> Array[
  @todo.Todo,
] {
  self.state.val.todos.iter().map(fn(pair) { pair.1 }).collect()
}

///|
pub impl @todo.TodoRepository for InMemoryStore with find_by_id(self, id) -> @todo.Todo? {
  self.state.val.todos.get(id)
}

///|
pub impl @todo.TodoRepository for InMemoryStore with save(self, todo) -> Unit {
  self.state.val = {
    ..self.state.val,
    todos: self.state.val.todos.add(todo.id(), todo),
  }
}

///|
pub impl @todo.TodoRepository for InMemoryStore with remove(self, id) -> Bool {
  guard self.state.val.todos.contains(id) else { return false }
  self.state.val = { ..self.state.val, todos: self.state.val.todos.remove(id) }
  true
}

///|
pub impl @todo.TodoRepository for InMemoryStore with next_id(self) -> Int {
  let id = self.state.val.next_id
  self.state.val = { ..self.state.val, next_id: id + 1 }
  id
}
