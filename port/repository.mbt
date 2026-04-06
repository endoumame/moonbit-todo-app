// Port — the interface that the domain requires from infrastructure.
// Driven adapter (e.g. InMemoryStore) must implement this trait.

///|
pub(open) trait TodoRepository {
  find_all(Self) -> Array[@domain.Todo]
  find_by_id(Self, Int) -> @domain.Todo?
  save(Self, @domain.Todo) -> Unit
  remove(Self, Int) -> Bool
  next_id(Self) -> Int
}
