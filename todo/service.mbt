// Application Services — orchestrate domain logic through the repository port.

///|
pub fn[R : TodoRepository] list(repo : R) -> Array[Todo] {
  repo.find_all()
}

///|
pub fn[R : TodoRepository] create(
  repo : R,
  raw_title : String,
) -> Result[(Todo, Array[DomainEvent]), DomainError] {
  match TodoTitle::create(raw_title) {
    Err(e) => Err(e)
    Ok(title) => {
      let todo = Todo::create(repo.next_id(), title)
      repo.save(todo)
      Ok((todo, [TodoCreated(todo)]))
    }
  }
}

///|
pub fn[R : TodoRepository] toggle(
  repo : R,
  id : Int,
) -> Result[(Todo, Array[DomainEvent]), DomainError] {
  match repo.find_by_id(id) {
    None => Err(TodoNotFound(id))
    Some(todo) => {
      let toggled = todo.toggle()
      repo.save(toggled)
      Ok((toggled, [TodoToggled(toggled)]))
    }
  }
}

///|
pub fn[R : TodoRepository] update(
  repo : R,
  id : Int,
  raw_title : String?,
  completed : Bool?,
) -> Result[(Todo, Array[DomainEvent]), DomainError] {
  match repo.find_by_id(id) {
    None => Err(TodoNotFound(id))
    Some(todo) =>
      match todo.apply_update(raw_title, completed) {
        Err(e) => Err(e)
        Ok(updated) => {
          repo.save(updated)
          Ok((updated, [TodoUpdated(updated)]))
        }
      }
  }
}

///|
pub fn[R : TodoRepository] delete(
  repo : R,
  id : Int,
) -> Result[Array[DomainEvent], DomainError] {
  guard repo.remove(id) else { return Err(TodoNotFound(id)) }
  Ok([TodoDeleted(id)])
}
