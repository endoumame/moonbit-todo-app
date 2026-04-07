// Driving adapter — HTTP routing and JSON/domain translation.

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

// Smart constructors as methods

///|
fn HttpResponse::json(status : Int, body : String) -> HttpResponse {
  { status, body, content_type: "application/json" }
}

///|
fn HttpResponse::html(body : String) -> HttpResponse {
  { status: 200, body, content_type: "text/html; charset=utf-8" }
}

///|
fn HttpResponse::error(status : Int, msg : String) -> HttpResponse {
  HttpResponse::json(
    status,
    Json::object({ "error": Json::string(msg) }).stringify(),
  )
}

///|
fn HttpResponse::from_result(
  result : Result[@todo.Todo, @todo.DomainError],
  ok_status : Int,
) -> HttpResponse {
  match result {
    Ok(todo) => HttpResponse::json(ok_status, todo.to_json().stringify())
    Err(e) => HttpResponse::from_domain_error(e)
  }
}

///|
fn HttpResponse::from_domain_error(err : @todo.DomainError) -> HttpResponse {
  match err {
    EmptyTitle => HttpResponse::error(400, "title must not be empty")
    TodoNotFound(id) => HttpResponse::error(404, "todo \{id} not found")
  }
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
    [.. "/todos/", .. rest] => Route::parse_todo_path(rest.to_string())
    _ => NotFound
  }
}

///|
fn Route::parse_todo_path(rest : String) -> Route {
  if rest.has_suffix("/toggle") {
    rest[:rest.length() - "/toggle".length()].to_string()
    |> parse_int_opt
    |> Option::map(fn(id) { TodoToggle(id) })
    |> Option::unwrap_or(NotFound)
  } else {
    rest
    |> parse_int_opt
    |> Option::map(fn(id) { TodoItem(id) })
    |> Option::unwrap_or(NotFound)
  }
}

///|
fn parse_int_opt(s : String) -> Int? {
  Some(@string.parse_int(s)) catch {
    _ => None
  }
}

// JSON body extraction

///|
fn extract_title(body : String) -> String? {
  match parse_json(body) {
    Some(Object(map)) =>
      match map.get("title") {
        Some(Json::String(s)) => Some(s)
        _ => None
      }
    _ => None
  }
}

///|
fn extract_fields(body : String) -> (String?, Bool?) {
  match parse_json(body) {
    Some(Object(map)) => {
      let title = match map.get("title") {
        Some(Json::String(s)) => Some(s)
        _ => None
      }
      let completed = match map.get("completed") {
        Some(True) => Some(true)
        Some(False) => Some(false)
        _ => None
      }
      (title, completed)
    }
    _ => (None, None)
  }
}

///|
fn parse_json(body : String) -> Json? {
  Some(@json.parse(body)) catch {
    _ => None
  }
}

// Router — pattern match (Method, Route), delegate to @todo services

///|
pub fn[R : @todo.TodoRepository] handle(
  repo : R,
  req_method : String,
  path : String,
  body : String,
) -> HttpResponse {
  match (Method::parse(req_method), Route::parse(path)) {
    (Get, Root) => HttpResponse::html(render_html())
    (Get, Todos) =>
      HttpResponse::json(200, @todo.list(repo).to_json().stringify())
    (Post, Todos) =>
      match extract_title(body) {
        Some(raw) => @todo.create(repo, raw) |> HttpResponse::from_result(201)
        None => HttpResponse::error(400, "title is required")
      }
    (Put, TodoToggle(id)) =>
      @todo.toggle(repo, id) |> HttpResponse::from_result(200)
    (Put, TodoItem(id)) => {
      let (title, completed) = extract_fields(body)
      @todo.update(repo, id, title, completed) |> HttpResponse::from_result(200)
    }
    (Delete, TodoItem(id)) =>
      match @todo.delete(repo, id) {
        Ok(_) => HttpResponse::json(200, "{\"deleted\":true}")
        Err(e) => HttpResponse::from_domain_error(e)
      }
    _ => HttpResponse::error(404, "not found")
  }
}
