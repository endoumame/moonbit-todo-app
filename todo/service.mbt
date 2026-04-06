// Application services — orchestrate domain logic through the repository port.

///|
pub fn[R : TodoRepository] list(repo : R) -> Array[Todo] {
  repo.find_all()
}

///|
pub fn[R : TodoRepository] create(
  repo : R,
  raw_title : String,
) -> Result[Todo, DomainError] {
  match TodoTitle::create(raw_title) {
    Err(e) => Err(e)
    Ok(title) => {
      let todo = Todo::create(repo.next_id(), title)
      repo.save(todo)
      Ok(todo)
    }
  }
}

///|
pub fn[R : TodoRepository] toggle(
  repo : R,
  id : Int,
) -> Result[Todo, DomainError] {
  match repo.find_by_id(id) {
    None => Err(TodoNotFound(id))
    Some(todo) => {
      let toggled = todo.toggle()
      repo.save(toggled)
      Ok(toggled)
    }
  }
}

///|
pub fn[R : TodoRepository] update(
  repo : R,
  id : Int,
  raw_title : String?,
  completed : Bool?,
) -> Result[Todo, DomainError] {
  match repo.find_by_id(id) {
    None => Err(TodoNotFound(id))
    Some(todo) => {
      let updated = match raw_title {
        Some(t) =>
          match TodoTitle::create(t) {
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
pub fn[R : TodoRepository] delete(
  repo : R,
  id : Int,
) -> Result[Unit, DomainError] {
  guard repo.remove(id) else { return Err(TodoNotFound(id)) }
  Ok(())
}
