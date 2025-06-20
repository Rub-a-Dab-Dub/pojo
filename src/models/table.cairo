use poker_game::models::game::{GameRound, GameStatus};

#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
struct Table {
    #[key]
    table_id: u32,
    dealer_position: u8,
    small_blind: u128,
    big_blind: u128,
    min_buy_in: u128,
    max_players: u8,
    player_count: u8,
    status: felt252, // GameStatus
    current_round: felt252, // GameRound
    pot_total: u128,
    current_bet: u128,
    current_player: u8,
    last_raise_amount: u128,
    round_action_count: u8,
}