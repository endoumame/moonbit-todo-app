// Always Valid Domain Model
// TodoTitle and Todo can only be constructed through validated smart constructors.
// The priv fields prevent external packages from creating invalid instances.

///|
pub struct TodoTitle {
  priv value : String
}

///|
pub fn TodoTitle::create(raw : String) -> Result[TodoTitle, DomainError] {
  let trimmed = raw.trim().to_string()
  if trimmed.length() == 0 {
    Err(EmptyTitle)
  } else {
    Ok({ value: trimmed })
  }
}

///|
pub fn TodoTitle::to_string(self : TodoTitle) -> String {
  self.value
}

///|
pub impl ToJson for TodoTitle with to_json(self) -> Json {
  Json::string(self.value)
}

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
pub impl ToJson for Todo with to_json(self) -> Json {
  Json::object({
    "id": Json::number(self.id_.to_double()),
    "title": self.title_.to_json(),
    "completed": Json::boolean(self.completed_),
  })
}
