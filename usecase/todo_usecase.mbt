// Use cases — application services that orchestrate domain logic.
// Depends only on domain types and port traits (never on adapters).

///|
pub fn[R : @port.TodoRepository] list_todos(repo : R) -> Array[@domain.Todo] {
  repo.find_all()
}

///|
pub fn[R : @port.TodoRepository] create_todo(
  repo : R,
  raw_title : String,
) -> Result[@domain.Todo, @domain.DomainError] {
  match @domain.TodoTitle::create(raw_title) {
    Err(e) => Err(e)
    Ok(title) => {
      let id = repo.next_id()
      let todo = @domain.Todo::create(id, title)
      repo.save(todo)
      Ok(todo)
    }
  }
}

///|
pub fn[R : @port.TodoRepository] toggle_todo(
  repo : R,
  id : Int,
) -> Result[@domain.Todo, @domain.DomainError] {
  match repo.find_by_id(id) {
    None => Err(@domain.TodoNotFound(id))
    Some(todo) => {
      let toggled = todo.toggle()
      repo.save(toggled)
      Ok(toggled)
    }
  }
}

///|
pub fn[R : @port.TodoRepository] update_todo(
  repo : R,
  id : Int,
  raw_title : String?,
  completed : Bool?,
) -> Result[@domain.Todo, @domain.DomainError] {
  match repo.find_by_id(id) {
    None => Err(@domain.TodoNotFound(id))
    Some(todo) => {
      let updated = match raw_title {
        Some(t) =>
          match @domain.TodoTitle::create(t) {
            Err(e) => return Err(e)
            Ok(title) => todo.with_title(title)
          }
        None => todo
      }
      let updated = match completed {
        Some(c) => updated.with_completed(c)
        None => updated
      }
      repo.save(updated)
      Ok(updated)
    }
  }
}

///|
pub fn[R : @port.TodoRepository] delete_todo(
  repo : R,
  id : Int,
) -> Result[Unit, @domain.DomainError] {
  if repo.remove(id) {
    Ok(())
  } else {
    Err(@domain.TodoNotFound(id))
  }
}
