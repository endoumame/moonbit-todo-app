///|
pub struct Todo {
  priv id_ : Int
  priv title_ : TodoTitle
  priv completed_ : Bool
}

///|
pub fn Todo::create(id : Int, title : TodoTitle) -> Todo {
  { id_: id, title_: title, completed_: false }
}

///|
pub fn Todo::id(self : Todo) -> Int {
  self.id_
}

///|
pub fn Todo::title(self : Todo) -> TodoTitle {
  self.title_
}

///|
pub fn Todo::completed(self : Todo) -> Bool {
  self.completed_
}

///|
pub fn Todo::toggle(self : Todo) -> Todo {
  { ..self, completed_: !self.completed_ }
}

///|
pub fn Todo::with_title(self : Todo, title : TodoTitle) -> Todo {
  { ..self, title_: title }
}

///|
pub fn Todo::with_completed(self : Todo, completed : Bool) -> Todo {
  { ..self, completed_: completed }
}

///|
pub fn Todo::apply_update(
  self : Todo,
  raw_title : String?,
  completed : Bool?,
) -> Result[Todo, DomainError] {
  let updated = match raw_title {
    Some(t) =>
      match TodoTitle::create(t) {
        Err(e) => return Err(e)
        Ok(title) => self.with_title(title)
      }
    None => self
  }
  let updated = match completed {
    Some(c) => updated.with_completed(c)
    None => updated
  }
  Ok(updated)
}

///|
pub impl ToJson for Todo with to_json(self) -> Json {
  Json::object({
    "id": Json::number(self.id_.to_double()),
    "title": self.title_.to_json(),
    "completed": Json::boolean(self.completed_),
  })
}
