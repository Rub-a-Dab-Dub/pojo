use starknet::{ContractAddress};

#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
struct Player {
    #[key]
    address: ContractAddress,
    #[key] 
    table_id: u32,
    stack: u128,
    current_bet: u128,
    hole_card1: u8,
    hole_card2: u8,
    is_active: bool,
    has_acted: bool,
    position: u8,
    last_action: felt252, // PlayerAction
}

#[derive(Copy, Drop, Serde, PartialEq, Introspect)]
enum PlayerAction {
    None,
    Check,
    Call,
    Raise,
    Fold,
    AllIn,
}

#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
struct TablePlayers {
    #[key]
    table_id: u32,
    players: Span<ContractAddress>,
}