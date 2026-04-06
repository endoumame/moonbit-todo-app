// Composition root — wires concrete adapters and exports entry point.

///|
let repo : @store.InMemoryStore = @store.InMemoryStore::new()

///|
fn main {
  // Required for main package
}

///|
pub fn handle_request(
  req_method : String,
  path : String,
  body : String,
) -> String {
  let resp = @http.handle(repo, req_method, path, body)
  Json::object({
    "status": Json::number(resp.status.to_double()),
    "body": Json::string(resp.body),
    "content_type": Json::string(resp.content_type),
  }).stringify()
}
