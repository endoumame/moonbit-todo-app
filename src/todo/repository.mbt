// Repository port — part of the domain's ubiquitous language.
// Infrastructure adapters implement this trait.

///|
pub(open) trait TodoRepository {
  find_all(Self) -> Array[Todo]
  find_by_id(Self, Int) -> Todo?
  save(Self, Todo) -> Unit
  remove(Self, Int) -> Bool
  next_id(Self) -> Int
}
