///|
pub struct TodoTitle {
  priv value : String
}

///|
pub fn TodoTitle::create(raw : String) -> Result[TodoTitle, DomainError] {
  let trimmed = raw.trim().to_string()
  guard trimmed.length() > 0 else { return Err(EmptyTitle) }
  Ok({ value: trimmed })
}

///|
pub fn TodoTitle::to_string(self : TodoTitle) -> String {
  self.value
}

///|
pub impl ToJson for TodoTitle with to_json(self) -> Json {
  Json::string(self.value)
}
