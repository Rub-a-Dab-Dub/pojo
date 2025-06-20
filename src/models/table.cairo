// use poker_game::models::game::{GameRound, GameStatus};

// #[derive(Copy, Drop, Serde, Debug)]
// #[dojo::model]
// struct Table {
//     #[key]
//     table_id: u32,
//     dealer_position: u8,
//     small_blind: u128,
//     big_blind: u128,
//     min_buy_in: u128,
//     max_players: u8,
//     player_count: u8,
//     status: felt252, // GameStatus
//     current_round: felt252, // GameRound
//     pot_total: u128,
//     current_bet: u128,
//     current_player: u8,
//     last_raise_amount: u128,
//     round_action_count: u8,
// }

// #[derive(Copy, Drop, Serde, Debug)]
// #[dojo::model]
// struct TablePlayers {
//     #[key]
//     table_id: u32,
//     players: Span<ContractAddress>,
// }

// #[generate_trait]
// pub impl TablePlayersImpl of TablePlayersTrait {
//     /// Add a player to the table
//     fn add_player(ref self: TablePlayers, player_address: ContractAddress) -> bool {
//         // Check if player already exists
//         let mut i = 0;
//         while i < self.players.len() {
//             if *self.players.at(i) == player_address {
//                 return false; // Player already at table
//             }
//             i += 1;
//         };

//         // In Cairo, we can't directly append to Span, so this would need
//         // to be handled at the system level where we reconstruct the Array
//         true
//     }

//     /// Get player count
//     fn get_player_count(self: @TablePlayers) -> u32 {
//         (*self.players).len()
//     }

//     /// Check if table has a specific player
//     fn has_player(self: @TablePlayers, player_address: ContractAddress) -> bool {
//         let mut i = 0;
//         while i < self.players.len() {
//             if *self.players.at(i) == player_address {
//                 return true;
//             }
//             i += 1;
//         };
//         false
//     }

//     /// Get player at specific position
//     fn get_player_at_position(self: @TablePlayers, position: u8) -> Option<ContractAddress> {
//         if position >= (*self.players).len().try_into().unwrap() {
//             Option::None
//         } else {
//             Option::Some(*self.players.at(position.into()))
//         }
//     }
// }
