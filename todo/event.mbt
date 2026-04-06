///|
pub(all) enum DomainEvent {
  TodoCreated(Todo)
  TodoToggled(Todo)
  TodoUpdated(Todo)
  TodoDeleted(Int)
} derive(Show)
