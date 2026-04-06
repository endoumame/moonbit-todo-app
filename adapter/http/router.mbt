// Driving adapter — translates HTTP into use case calls and domain results back to HTTP.
// This layer knows about JSON and HTTP status codes; the domain does not.

///|
priv enum Method {
  Get
  Post
  Put
  Delete
  Other
}

///|
priv enum Route {
  Root
  Todos
  TodoToggle(Int)
  TodoItem(Int)
  NotFound
}

///|
pub(all) struct HttpResponse {
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
    _ => Other
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
fn json_ok(body : String) -> HttpResponse {
  { status: 200, body, content_type: "application/json" }
}

///|
fn json_created(body : String) -> HttpResponse {
  { status: 201, body, content_type: "application/json" }
}

///|
fn json_error(status : Int, msg : String) -> HttpResponse {
  let body = Json::object({ "error": Json::string(msg) }).stringify()
  { status, body, content_type: "application/json" }
}

///|
fn html_ok(body : String) -> HttpResponse {
  { status: 200, body, content_type: "text/html; charset=utf-8" }
}

// Domain result → HTTP response mapping

///|
fn domain_error_to_response(err : @domain.DomainError) -> HttpResponse {
  match err {
    EmptyTitle => json_error(400, "title must not be empty")
    TodoNotFound(id) => json_error(404, "todo \{id} not found")
    InvalidId(s) => json_error(400, "invalid id: \{s}")
  }
}

///|
fn ok_or_domain_error(
  result : Result[@domain.Todo, @domain.DomainError],
) -> HttpResponse {
  match result {
    Ok(todo) => todo.to_json().stringify() |> json_ok
    Err(e) => domain_error_to_response(e)
  }
}

///|
fn created_or_domain_error(
  result : Result[@domain.Todo, @domain.DomainError],
) -> HttpResponse {
  match result {
    Ok(todo) => todo.to_json().stringify() |> json_created
    Err(e) => domain_error_to_response(e)
  }
}

// JSON request body extraction

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
            Json::String(s) => Some(s)
            _ => None
          }
        })
      _ => None
    }
  })
}

///|
fn extract_fields(body : String) -> (String?, Bool?) {
  match parse_body(body) {
    Some(Object(map)) => {
      let title = map
        .get("title")
        .bind(fn(v) {
          match v {
            Json::String(s) => Some(s)
            _ => None
          }
        })
      let completed = map
        .get("completed")
        .bind(fn(v) {
          match v {
            True => Some(true)
            False => Some(false)
            _ => None
          }
        })
      (title, completed)
    }
    _ => (None, None)
  }
}

// Router — pattern match (Method, Route), delegate to use cases

///|
pub fn[R : @port.TodoRepository] handle(
  repo : R,
  req_method : String,
  path : String,
  body : String,
) -> HttpResponse {
  match (Method::parse(req_method), Route::parse(path)) {
    (Get, Root) => html_ok(render_html())
    (Get, Todos) => @usecase.list_todos(repo).to_json().stringify() |> json_ok
    (Post, Todos) =>
      match extract_title(body) {
        Some(raw_title) =>
          @usecase.create_todo(repo, raw_title) |> created_or_domain_error
        None => json_error(400, "title is required")
      }
    (Put, TodoToggle(id)) =>
      @usecase.toggle_todo(repo, id) |> ok_or_domain_error
    (Put, TodoItem(id)) => {
      let (title, completed) = extract_fields(body)
      @usecase.update_todo(repo, id, title, completed) |> ok_or_domain_error
    }
    (Delete, TodoItem(id)) =>
      match @usecase.delete_todo(repo, id) {
        Ok(_) => json_ok("{\"deleted\":true}")
        Err(e) => domain_error_to_response(e)
      }
    _ => json_error(404, "not found")
  }
}
