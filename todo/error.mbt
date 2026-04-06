// Domain errors — what can go wrong in the Todo domain

///|
pub(all) enum DomainError {
  EmptyTitle
  TodoNotFound(Int)
} derive(Show)
