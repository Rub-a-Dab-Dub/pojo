#[derive(Copy, Drop, Serde, PartialEq, Introspect)]
pub enum GameRound {
    PreFlop,
    Flop,
    Turn,
    River,
    Showdown,
}

#[derive(Copy, Drop, Serde, PartialEq, Introspect)]
pub enum GameStatus {
    Waiting,
    InProgress,
    Showdown,
    Finished,
}
