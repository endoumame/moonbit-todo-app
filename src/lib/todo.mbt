// Todo data model with automatic JSON serialization

///|
struct Todo {
  id : Int
  title : String
  completed : Bool
} derive(ToJson, FromJson, Show)

// Application state — immutable sorted map wrapped in a Ref for controlled mutation

///|
struct Store {
  todos : @sorted_map.SortedMap[Int, Todo]
  next_id : Int
}

///|
let store : Ref[Store] = {
  val: { todos: @sorted_map.SortedMap::new(), next_id: 1 },
}

///|
fn[T] with_store(f : (Store) -> (Store, T)) -> T {
  let (new_store, result) = f(store.val)
  store.val = new_store
  result
}

///|
fn[T] read_store(f : (Store) -> T) -> T {
  f(store.val)
}

// Pure functions over Store

///|
fn Store::add(self : Store, title : String) -> (Store, Todo) {
  let todo = { id: self.next_id, title, completed: false }
  let new_store = {
    todos: self.todos.add(todo.id, todo),
    next_id: self.next_id + 1,
  }
  (new_store, todo)
}

///|
fn Store::all(self : Store) -> Array[Todo] {
  self.todos.iter().map(fn(pair) { pair.1 }).collect()
}

///|
fn Store::update(self : Store, id : Int, f : (Todo) -> Todo) -> (Store, Todo?) {
  match self.todos.get(id) {
    None => (self, None)
    Some(todo) => {
      let updated = f(todo)
      ({ ..self, todos: self.todos.add(id, updated) }, Some(updated))
    }
  }
}

///|
fn Store::remove(self : Store, id : Int) -> (Store, Bool) {
  if self.todos.contains(id) {
    ({ ..self, todos: self.todos.remove(id) }, true)
  } else {
    (self, false)
  }
}
