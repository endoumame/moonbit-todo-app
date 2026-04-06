// Domain errors — exhaustive set of what can go wrong in the domain

///|
pub(all) enum DomainError {
  EmptyTitle
  TodoNotFound(Int)
  InvalidId(String)
} derive(Show)
