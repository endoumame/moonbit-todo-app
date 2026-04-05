// HTTP request routing and response handling

///|
enum Method {
  Get
  Post
  Put
  Delete
  Unknown
}

///|
enum Route {
  Root
  Todos
  TodoItem(Int)
  TodoToggle(Int)
  NotFound
}

///|
struct Response {
  status : Int
  body : String
  content_type : String
}

// Parsing

///|
fn Method::parse(s : String) -> Method {
  match s {
    "GET" => Get
    "POST" => Post
    "PUT" => Put
    "DELETE" => Delete
    _ => Unknown
  }
}

///|
fn Route::parse(path : String) -> Route {
  match path {
    "/" => Root
    "/todos" => Todos
    _ =>
      if path.has_prefix("/todos/") && path.has_suffix("/toggle") {
        path["/todos/".length():path.length() - "/toggle".length()].to_string()
        |> parse_int_opt
        |> Option::map(fn(id) { TodoToggle(id) })
        |> Option::unwrap_or(NotFound)
      } else if path.has_prefix("/todos/") {
        path["/todos/".length():].to_string()
        |> parse_int_opt
        |> Option::map(fn(id) { TodoItem(id) })
        |> Option::unwrap_or(NotFound)
      } else {
        NotFound
      }
  }
}

///|
fn parse_int_opt(s : String) -> Int? {
  Some(@string.parse_int(s)) catch {
    _ => None
  }
}

// Response constructors

///|
fn json_ok(body : String) -> Response {
  { status: 200, body, content_type: "application/json" }
}

///|
fn json_created(body : String) -> Response {
  { status: 201, body, content_type: "application/json" }
}

///|
fn json_error(status : Int, msg : String) -> Response {
  let json = Json::object({ "error": Json::string(msg) })
  { status, body: json.stringify(), content_type: "application/json" }
}

///|
fn html_ok(body : String) -> Response {
  { status: 200, body, content_type: "text/html; charset=utf-8" }
}

///|
fn todo_json(todo : Todo) -> String {
  todo.to_json().stringify()
}

///|
fn todos_json(todos : Array[Todo]) -> String {
  todos.to_json().stringify()
}

// Request body parsing via @json

///|
fn parse_body(body : String) -> Json? {
  Some(@json.parse(body)) catch {
    _ => None
  }
}

///|
fn extract_title(body : String) -> String? {
  parse_body(body).bind(fn(json) {
    match json {
      Object(map) =>
        map
        .get("title")
        .bind(fn(v) {
          match v {
            Json::String(s) if s.length() > 0 => Some(s)
            _ => None
          }
        })
      _ => None
    }
  })
}

///|
fn get_string(json : Json) -> String? {
  match json {
    Json::String(s) => Some(s)
    _ => None
  }
}

///|
fn get_bool(json : Json) -> Bool? {
  match json {
    True => Some(true)
    False => Some(false)
    _ => None
  }
}

///|
fn extract_fields(body : String) -> (String?, Bool?) {
  match parse_body(body) {
    Some(Object(map)) => {
      let title = map.get("title").bind(get_string)
      let completed = map.get("completed").bind(get_bool)
      (title, completed)
    }
    _ => (None, None)
  }
}

// Router — pattern match on (Method, Route)

///|
fn route(req_method : String, path : String, body : String) -> Response {
  match (Method::parse(req_method), Route::parse(path)) {
    (Get, Root) => html_ok(render_html())
    (Get, Todos) => read_store(Store::all) |> todos_json |> json_ok
    (Post, Todos) =>
      match extract_title(body) {
        Some(title) =>
          with_store(fn(s) { s.add(title) }) |> todo_json |> json_created
        None => json_error(400, "title is required")
      }
    (Put, TodoToggle(id)) =>
      with_store(fn(s) {
        s.update(id, fn(t) { { ..t, completed: !t.completed } })
      })
      |> option_to_response
    (Put, TodoItem(id)) => {
      let (title, completed) = extract_fields(body)
      with_store(fn(s) {
        s.update(id, fn(t) {
          {
            ..t,
            title: title.unwrap_or(t.title),
            completed: completed.unwrap_or(t.completed),
          }
        })
      })
      |> option_to_response
    }
    (Delete, TodoItem(id)) =>
      if with_store(fn(s) { s.remove(id) }) {
        json_ok("{\"deleted\":true}")
      } else {
        json_error(404, "todo not found")
      }
    _ => json_error(404, "not found")
  }
}

///|
fn option_to_response(opt : Todo?) -> Response {
  match opt {
    Some(todo) => todo |> todo_json |> json_ok
    None => json_error(404, "todo not found")
  }
}

// Public entry point

///|
fn main {
  // Required for main package; logic is driven by handle_request from JS
}

///|
pub fn handle_request(
  req_method : String,
  path : String,
  body : String,
) -> String {
  let resp = route(req_method, path, body)
  let result = Json::object({
    "status": Json::number(resp.status.to_double()),
    "body": Json::string(resp.body),
    "content_type": Json::string(resp.content_type),
  })
  result.stringify()
}
