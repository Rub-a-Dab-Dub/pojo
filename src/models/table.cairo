use starknet::ContractAddress;

#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct Table {
    #[key]
    pub table_id: u32,
    pub creator: ContractAddress,
    pub dealer_position: u8,
    pub small_blind: u128,
    pub big_blind: u128,
    pub min_buy_in: u128,
    pub max_buy_in: u128,
    pub max_players: u8,
    pub current_players: u8,
    pub status: felt252, //GameStatus
    pub current_round: felt252, //GameRound
    pub pot_total: u128,
    pub current_bet: u128,
    pub current_player_position: u8,
    pub last_raise_amount: u128,
    pub players_acted_this_round: u8,
    // reps the hands (For tracking multiple games at same table)
    pub game_number: u32,
}

#[derive(Copy, Drop, Serde, PartialEq, Introspect)]
pub enum GameStatus {
    Waiting, // Waiting for players to join
    InProgress, // Game is running
    Showdown, // Final card reveal and hand comparison
    // Game completed, pot distributed
    Finished,
}

impl GameStatusIntoFelt252 of Into<GameStatus, felt252> {
    fn into(self: GameStatus) -> felt252 {
        match self {
            GameStatus::Waiting => 'WAITING',
            GameStatus::InProgress => 'IN_PROGRESS',
            GameStatus::Showdown => 'SHOWDOWN',
            GameStatus::Finished => 'FINISHED',
        }
    }
}

impl Felt252TryIntoGameStatus of TryInto<felt252, GameStatus> {
    fn try_into(self: felt252) -> Option<GameStatus> {
        if self == 'WAITING' {
            Option::Some(GameStatus::Waiting)
        } else if self == 'IN_PROGRESS' {
            Option::Some(GameStatus::InProgress)
        } else if self == 'SHOWDOWN' {
            Option::Some(GameStatus::Showdown)
        } else if self == 'FINISHED' {
            Option::Some(GameStatus::Finished)
        } else {
            Option::None
        }
    }
}

#[derive(Copy, Drop, Serde, PartialEq, Introspect)]
pub enum GameRound {
    PreFlop, // Before community cards
    Flop, // First 3 community cards
    Turn, // 4th community card
    River, // 5th community card
    // Compare hands
    Showdown,
}

impl GameRoundIntoFelt252 of Into<GameRound, felt252> {
    fn into(self: GameRound) -> felt252 {
        match self {
            GameRound::PreFlop => 'PREFLOP',
            GameRound::Flop => 'FLOP',
            GameRound::Turn => 'TURN',
            GameRound::River => 'RIVER',
            GameRound::Showdown => 'SHOWDOWN',
        }
    }
}

impl Felt252TryIntoGameRound of TryInto<felt252, GameRound> {
    fn try_into(self: felt252) -> Option<GameRound> {
        if self == 'PREFLOP' {
            Option::Some(GameRound::PreFlop)
        } else if self == 'FLOP' {
            Option::Some(GameRound::Flop)
        } else if self == 'TURN' {
            Option::Some(GameRound::Turn)
        } else if self == 'RIVER' {
            Option::Some(GameRound::River)
        } else if self == 'SHOWDOWN' {
            Option::Some(GameRound::Showdown)
        } else {
            Option::None
        }
    }
}


#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct GameDeck {
    #[key]
    pub table_id: u32,
    #[key]
    pub game_number: u32,
    pub cards: Span<u8>, // Shuffled deck indices
    pub next_card_index: u8,
    pub seed: u256,
}

#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct CommunityCards {
    #[key]
    pub table_id: u32,
    #[key]
    pub game_number: u32,
    pub flop1: u8,
    pub flop2: u8,
    pub flop3: u8,
    pub turn: u8,
    pub river: u8,
    // 0=none, 3=flop, 4=turn, 5=river
    pub cards_dealt: u8,
}

#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct TablePlayers {
    #[key]
    pub table_id: u32,
    pub players: Span<ContractAddress>,
    pub player_count: u8,
}

// For tracking side pots when players go all-in
#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct SidePot {
    #[key]
    pub table_id: u32,
    #[key]
    pub game_number: u32,
    #[key]
    pub pot_id: u8,
    pub amount: u128,
    pub eligible_players: Span<ContractAddress>,
}

// #[derive(Drop, starknet::Event)]
// struct TableCreated {
//     table_id: u32,
//     creator: ContractAddress,
//     big_blind: u128,
//     max_players: u8,
// }

// #[derive(Drop, starknet::Event)]
// struct PlayerJoinedTable {
//     table_id: u32,
//     player: ContractAddress,
//     position: u8,
//     buy_in: u128,
// }

// #[derive(Drop, starknet::Event)]
// struct GameStarted {
//     table_id: u32,
//     game_number: u32,
//     dealer_position: u8,
//     players: Span<ContractAddress>,
// }

// #[derive(Drop, starknet::Event)]
// struct PlayerActed {
//     table_id: u32,
//     game_number: u32,
//     player: ContractAddress,
//     action: felt252, // PlayerAction as felt252
//     amount: u128,
//     new_pot_total: u128,
// }

// #[derive(Drop, starknet::Event)]
// struct CommunityCardsDealt {
//     table_id: u32,
//     game_number: u32,
//     round: GameRound,
//     cards: Span<u8>,
// }

// #[derive(Drop, starknet::Event)]
// struct GameEnded {
//     table_id: u32,
//     game_number: u32,
//     winners: Span<ContractAddress>,
//     pot_amounts: Span<u128>,
// }

// #[derive(Drop, starknet::Event)]
// struct RoundAdvanced {
//     table_id: u32,
//     game_number: u32,
//     new_round: GameRound,
//     reset_betting: bool,
// }

#[generate_trait]
pub impl TableImpl of TableTrait {
    /// Create a new table
    fn new(
        table_id: u32,
        creator: ContractAddress,
        small_blind: u128,
        big_blind: u128,
        min_buy_in: u128,
        max_buy_in: u128,
        max_players: u8,
    ) -> Table {
        Table {
            table_id,
            creator,
            dealer_position: 0,
            small_blind,
            big_blind,
            min_buy_in,
            max_buy_in,
            max_players,
            current_players: 0,
            status: GameStatus::Waiting.into(),
            current_round: GameRound::PreFlop.into(),
            pot_total: 0,
            current_bet: 0,
            current_player_position: 0,
            last_raise_amount: 0,
            players_acted_this_round: 0,
            game_number: 0,
        }
    }

    /// Check if table can accept a new player
    fn can_join(self: @Table) -> bool {
        *self.status == GameStatus::Waiting.into() && *self.current_players < *self.max_players
    }

    /// Add a player to the table
    fn add_player(ref self: Table) -> bool {
        if !self.can_join() {
            return false;
        }

        self.current_players += 1;
        true
    }

    /// Check if table has enough players to start
    fn can_start_game(self: @Table) -> bool {
        *self.current_players >= 2 && *self.status == GameStatus::Waiting.into()
    }

    /// Start a new game
    fn start_game(ref self: Table) -> bool {
        if !self.can_start_game() {
            return false;
        }

        self.status = GameStatus::InProgress.into();
        self.current_round = GameRound::PreFlop.into();
        self.pot_total = 0;
        self.current_bet = 0;
        self.last_raise_amount = 0;
        self.players_acted_this_round = 0;
        self.game_number += 1;

        // Set first player after big blind as current player
        self.current_player_position = self.get_next_position_after_blinds();

        true
    }

    /// Get position after big blind (first to act preflop)
    fn get_next_position_after_blinds(self: @Table) -> u8 {
        if *self.current_players == 2 {
            // Heads up: small blind acts first preflop
            (*self.dealer_position + 1) % *self.current_players
        } else {
            // 3+ players: position after big blind acts first
            (*self.dealer_position + 3) % *self.current_players
        }
    }

    /// Post blinds and set initial betting state
    fn post_blinds(ref self: Table) {
        self.pot_total = self.small_blind + self.big_blind;
        self.current_bet = self.big_blind;
        self.last_raise_amount = self.big_blind;
    }

    /// Add amount to pot
    fn add_to_pot(ref self: Table, amount: u128) {
        self.pot_total += amount;
    }

    /// Update current bet (for raises)
    fn update_current_bet(ref self: Table, new_bet: u128, raise_amount: u128) {
        self.current_bet = new_bet;
        self.last_raise_amount = raise_amount;
    }

    /// Move to next player
    fn advance_to_next_player(ref self: Table) {
        self.current_player_position = (self.current_player_position + 1) % self.current_players;
        self.players_acted_this_round += 1;
    }

    /// Check if betting round is complete
    fn is_betting_round_complete(self: @Table, active_players: u8) -> bool {
        *self.players_acted_this_round >= active_players
    }

    /// Advance to next round (flop -> turn -> river -> showdown)
    fn advance_round(ref self: Table) -> bool {
        let current_round: GameRound = self.current_round.try_into().unwrap();
        match current_round {
            GameRound::PreFlop => {
                self.current_round = GameRound::Flop.into();
                self.reset_betting_round();
                true
            },
            GameRound::Flop => {
                self.current_round = GameRound::Turn.into();
                self.reset_betting_round();
                true
            },
            GameRound::Turn => {
                self.current_round = GameRound::River.into();
                self.reset_betting_round();
                true
            },
            GameRound::River => {
                self.current_round = GameRound::Showdown.into();
                self.status = GameStatus::Showdown.into();
                true
            },
            GameRound::Showdown => false // Can't advance from showdown
        }
    }

    /// Reset betting state for new round
    fn reset_betting_round(ref self: Table) {
        self.current_bet = 0;
        self.players_acted_this_round = 0;
        self.last_raise_amount = 0;

        // Set first active player after dealer as current player
        self.current_player_position = (self.dealer_position + 1) % self.current_players;
    }

    /// End the current game
    fn end_game(ref self: Table) {
        self.status = GameStatus::Finished.into();
        self.current_round = GameRound::PreFlop.into();

        // Move dealer button
        self.dealer_position = (self.dealer_position + 1) % self.current_players;

        // Reset for potential next game
        self.pot_total = 0;
        self.current_bet = 0;
        self.last_raise_amount = 0;
        self.players_acted_this_round = 0;
    }

    /// Prepare for next game at the same table
    fn prepare_next_game(ref self: Table) {
        if self.current_players >= 2 {
            self.status = GameStatus::Waiting.into(); // Ready for next game
        }
    }

    /// Get minimum raise amount
    fn get_min_raise(self: @Table) -> u128 {
        if *self.current_round == GameRound::PreFlop.into() {
            *self.big_blind // Minimum raise is big blind
        } else {
            if *self.last_raise_amount > *self.big_blind {
                *self.last_raise_amount
            } else {
                *self.big_blind
            }
        }
    }

    /// Validate table state
    fn validate_state(self: @Table) -> bool {
        if *self.current_players > *self.max_players {
            return false;
        }

        if *self.dealer_position >= *self.current_players && *self.current_players > 0 {
            return false;
        }

        if *self.big_blind <= *self.small_blind {
            return false;
        }

        true
    }
}

#[generate_trait]
pub impl CommunityCardsImpl of CommunityCardsTrait {
    fn new(table_id: u32, game_number: u32) -> CommunityCards {
        CommunityCards {
            table_id,
            game_number,
            flop1: 255, // Invalid until dealt
            flop2: 255,
            flop3: 255,
            turn: 255,
            river: 255,
            cards_dealt: 0,
        }
    }

    fn deal_flop(ref self: CommunityCards, card1: u8, card2: u8, card3: u8) {
        assert(self.cards_dealt == 0, 'Flop already dealt');
        assert(card1 < 52 && card2 < 52 && card3 < 52, 'Invalid card indices');

        self.flop1 = card1;
        self.flop2 = card2;
        self.flop3 = card3;
        self.cards_dealt = 3;
    }

    fn deal_turn(ref self: CommunityCards, card: u8) {
        assert(self.cards_dealt == 3, 'Must deal flop first');
        assert(card < 52, 'Invalid card index');

        self.turn = card;
        self.cards_dealt = 4;
    }

    fn deal_river(ref self: CommunityCards, card: u8) {
        assert(self.cards_dealt == 4, 'Must deal turn first');
        assert(card < 52, 'Invalid card index');

        self.river = card;
        self.cards_dealt = 5;
    }

    fn get_dealt_cards(self: @CommunityCards) -> Array<u8> {
        let mut cards: Array<u8> = array![];

        if *self.cards_dealt >= 3 {
            cards.append(*self.flop1);
            cards.append(*self.flop2);
            cards.append(*self.flop3);
        }

        if *self.cards_dealt >= 4 {
            cards.append(*self.turn);
        }

        if *self.cards_dealt >= 5 {
            cards.append(*self.river);
        }

        cards
    }

    fn get_all_cards(self: @CommunityCards) -> Array<u8> {
        array![*self.flop1, *self.flop2, *self.flop3, *self.turn, *self.river]
    }

    fn has_flop(self: @CommunityCards) -> bool {
        *self.cards_dealt >= 3
    }

    fn has_turn(self: @CommunityCards) -> bool {
        *self.cards_dealt >= 4
    }

    fn has_river(self: @CommunityCards) -> bool {
        *self.cards_dealt >= 5
    }
}

#[generate_trait]
pub impl GameDeckImpl of GameDeckTrait {
    fn new(table_id: u32, game_number: u32, shuffled_cards: Span<u8>, seed: u256) -> GameDeck {
        GameDeck { table_id, game_number, cards: shuffled_cards, next_card_index: 0, seed }
    }

    fn deal_next_card(ref self: GameDeck) -> u8 {
        assert(self.next_card_index < 52, 'No more cards in deck');

        let card = *self.cards.at(self.next_card_index.into());
        self.next_card_index += 1;
        card
    }

    fn deal_multiple_cards(ref self: GameDeck, count: u8) -> Array<u8> {
        let mut cards: Array<u8> = array![];
        let mut i = 0;

        while i < count {
            cards.append(self.deal_next_card());
            i += 1;
        };

        cards
    }

    fn cards_remaining(self: @GameDeck) -> u8 {
        52 - *self.next_card_index
    }

    fn peek_next_card(self: @GameDeck) -> u8 {
        assert(*self.next_card_index < 52, 'No more cards in deck');
        *((*self.cards).at((*self.next_card_index).into()))
    }
}

#[cfg(test)]
mod table_tests {
    use super::*;
    use starknet::{contract_address_const, ContractAddress};

    // Test addresses
    fn alice() -> ContractAddress {
        contract_address_const::<0x1>()
    }
    fn bob() -> ContractAddress {
        contract_address_const::<0x2>()
    }
    fn charlie() -> ContractAddress {
        contract_address_const::<0x3>()
    }

    // ENUM CONVERSION TESTS //

    #[test]
    fn test_game_status_conversions() {
        // Test GameStatus to felt252
        let waiting: felt252 = GameStatus::Waiting.into();
        assert(waiting == 'WAITING', 'waiting conv fail');

        let in_progress: felt252 = GameStatus::InProgress.into();
        assert(in_progress == 'IN_PROGRESS', 'progress conv fail');

        let showdown: felt252 = GameStatus::Showdown.into();
        assert(showdown == 'SHOWDOWN', 'showdown conv fail');

        let finished: felt252 = GameStatus::Finished.into();
        assert(finished == 'FINISHED', 'finished conv fail');

        // Test felt252 to GameStatus
        let back_to_waiting: GameStatus = 'WAITING'.try_into().unwrap();
        assert(back_to_waiting == GameStatus::Waiting, 'waiting rev fail');

        let back_to_progress: GameStatus = 'IN_PROGRESS'.try_into().unwrap();
        assert(back_to_progress == GameStatus::InProgress, 'progress rev fail');

        let back_to_showdown: GameStatus = 'SHOWDOWN'.try_into().unwrap();
        assert(back_to_showdown == GameStatus::Showdown, 'showdown rev fail');

        let back_to_finished: GameStatus = 'FINISHED'.try_into().unwrap();
        assert(back_to_finished == GameStatus::Finished, 'finished rev fail');

        // Test invalid conversion
        let invalid: Option<GameStatus> = 'INVALID'.try_into();
        assert(invalid.is_none(), 'invalid should be none');
    }

    #[test]
    fn test_game_round_conversions() {
        // Test GameRound to felt252
        let preflop: felt252 = GameRound::PreFlop.into();
        assert(preflop == 'PREFLOP', 'preflop conv fail');

        let flop: felt252 = GameRound::Flop.into();
        assert(flop == 'FLOP', 'flop conv fail');

        let turn: felt252 = GameRound::Turn.into();
        assert(turn == 'TURN', 'turn conv fail');

        let river: felt252 = GameRound::River.into();
        assert(river == 'RIVER', 'river conv fail');

        let showdown: felt252 = GameRound::Showdown.into();
        assert(showdown == 'SHOWDOWN', 'showdown conv fail');

        // Test felt252 to GameRound
        let back_to_preflop: GameRound = 'PREFLOP'.try_into().unwrap();
        assert(back_to_preflop == GameRound::PreFlop, 'preflop rev fail');

        let back_to_flop: GameRound = 'FLOP'.try_into().unwrap();
        assert(back_to_flop == GameRound::Flop, 'flop rev fail');

        let back_to_turn: GameRound = 'TURN'.try_into().unwrap();
        assert(back_to_turn == GameRound::Turn, 'turn rev fail');

        let back_to_river: GameRound = 'RIVER'.try_into().unwrap();
        assert(back_to_river == GameRound::River, 'river rev fail');

        let back_to_showdown: GameRound = 'SHOWDOWN'.try_into().unwrap();
        assert(back_to_showdown == GameRound::Showdown, 'showdown rev fail');

        // Test invalid conversion
        let invalid: Option<GameRound> = 'INVALID'.try_into();
        assert(invalid.is_none(), 'invalid should be none');
    }

    // TABLE TRAIT TESTS //

    #[test]
    fn test_table_creation() {
        let table = TableImpl::new(
            table_id: 1,
            creator: alice(),
            small_blind: 10,
            big_blind: 20,
            min_buy_in: 400,
            max_buy_in: 2000,
            max_players: 6,
        );

        assert(table.table_id == 1, 'wrong table id');
        assert(table.creator == alice(), 'wrong creator');
        assert(table.small_blind == 10, 'wrong small blind');
        assert(table.big_blind == 20, 'wrong big blind');
        assert(table.min_buy_in == 400, 'wrong min buy-in');
        assert(table.max_buy_in == 2000, 'wrong max buy-in');
        assert(table.max_players == 6, 'wrong max players');
        assert(table.current_players == 0, 'should start with 0 players');
        assert(table.dealer_position == 0, 'dealer should start at 0');
        assert(table.status == GameStatus::Waiting.into(), 'should start waiting');
        assert(table.current_round == GameRound::PreFlop.into(), 'should start preflop');
        assert(table.pot_total == 0, 'should start with 0 pot');
        assert(table.current_bet == 0, 'should start with 0 bet');
        assert(table.last_raise_amount == 0, 'should start with 0 raise');
        assert(table.players_acted_this_round == 0, 'should start with 0 actions');
        assert(table.game_number == 0, 'should start with game 0');
    }

    #[test]
    fn test_table_can_join() {
        let mut table = TableImpl::new(1, alice(), 10, 20, 400, 2000, 6);

        // Should be able to join initially
        assert(table.can_join(), 'should join empty table');

        // Add players
        table.current_players = 5;
        assert(table.can_join(), 'should join with 5 players');

        // Fill table
        table.current_players = 6;
        assert(!table.can_join(), 'should not join full table');

        // Start game
        table.current_players = 2;
        table.status = GameStatus::InProgress.into();
        assert(!table.can_join(), 'should not join in progress');
    }

    #[test]
    fn test_table_add_player() {
        let mut table = TableImpl::new(1, alice(), 10, 20, 400, 2000, 6);

        // Add first player
        let success1 = table.add_player();
        assert(success1, 'should add first player');
        assert(table.current_players == 1, 'should have 1 player');

        // Add second player
        let success2 = table.add_player();
        assert(success2, 'should add second player');
        assert(table.current_players == 2, 'should have 2 players');

        // Fill table
        table.current_players = 6;
        let fail = table.add_player();
        assert(!fail, 'should fail to add to full');
        assert(table.current_players == 6, 'count should not change');
    }

    #[test]
    fn test_table_can_start_game() {
        let mut table = TableImpl::new(1, alice(), 10, 20, 400, 2000, 6);

        // Cannot start with 0 players
        assert(!table.can_start_game(), 'should not start with 0');

        // Cannot start with 1 player
        table.current_players = 1;
        assert(!table.can_start_game(), 'should not start with 1');

        // Can start with 2 players
        table.current_players = 2;
        assert(table.can_start_game(), 'should start with 2');

        // Can start with more players
        table.current_players = 6;
        assert(table.can_start_game(), 'should start with 6');

        // Cannot start if already in progress
        table.status = GameStatus::InProgress.into();
        assert(!table.can_start_game(), 'should not start if active');
    }

    #[test]
    fn test_table_start_game() {
        let mut table = TableImpl::new(1, alice(), 10, 20, 400, 2000, 6);

        // Should fail with insufficient players
        let fail = table.start_game();
        assert(!fail, 'should fail with 0 players');

        // Add players and start
        table.current_players = 2;
        let success = table.start_game();
        assert(success, 'should start game');

        assert(table.status == GameStatus::InProgress.into(), 'should be in progress');
        assert(table.current_round == GameRound::PreFlop.into(), 'should be preflop');
        assert(table.game_number == 1, 'should be game 1');
        assert(table.pot_total == 0, 'pot should be reset');
        assert(table.current_bet == 0, 'bet should be reset');
        assert(table.last_raise_amount == 0, 'raise should be reset');
        assert(table.players_acted_this_round == 0, 'actions should be reset');

        // Current player should be set correctly
        let expected_position = table.get_next_position_after_blinds();
        assert(table.current_player_position == expected_position, 'wrong current player');
    }

    #[test]
    fn test_get_next_position_after_blinds() {
        let mut table = TableImpl::new(1, alice(), 10, 20, 400, 2000, 6);

        // Test heads-up (2 players)
        table.current_players = 2;
        table.dealer_position = 0;
        let heads_up_next = table.get_next_position_after_blinds();
        assert(heads_up_next == 1, 'hu pos 1 should act first');

        // Test with dealer at position 1
        table.dealer_position = 1;
        let heads_up_next2 = table.get_next_position_after_blinds();
        assert(heads_up_next2 == 0, 'hu after dealer acts first');

        // Test 3+ players
        table.current_players = 3;
        table.dealer_position = 0;
        let multi_next = table.get_next_position_after_blinds();
        assert(multi_next == 0, 'with 3 players (3) % 3 = 0');

        table.current_players = 6;
        table.dealer_position = 2;
        let six_player_next = table.get_next_position_after_blinds();
        assert(six_player_next == 5, 'with 6 (2+3) % 6 = 5');
    }

    #[test]
    fn test_post_blinds() {
        let mut table = TableImpl::new(1, alice(), 10, 20, 400, 2000, 6);

        table.post_blinds();

        assert(table.pot_total == 30, 'pot should be sb + bb');
        assert(table.current_bet == 20, 'bet should be bb');
        assert(table.last_raise_amount == 20, 'raise should be bb');
    }

    #[test]
    fn test_add_to_pot() {
        let mut table = TableImpl::new(1, alice(), 10, 20, 400, 2000, 6);

        table.add_to_pot(100);
        assert(table.pot_total == 100, 'pot should increase by 100');

        table.add_to_pot(50);
        assert(table.pot_total == 150, 'pot should be 150');
    }

    #[test]
    fn test_update_current_bet() {
        let mut table = TableImpl::new(1, alice(), 10, 20, 400, 2000, 6);

        table.update_current_bet(100, 50);
        assert(table.current_bet == 100, 'bet should be 100');
        assert(table.last_raise_amount == 50, 'raise should be 50');
    }

    #[test]
    fn test_advance_to_next_player() {
        let mut table = TableImpl::new(1, alice(), 10, 20, 400, 2000, 6);
        table.current_players = 3;
        table.current_player_position = 0;
        table.players_acted_this_round = 0;

        table.advance_to_next_player();
        assert(table.current_player_position == 1, 'should advance to 1');
        assert(table.players_acted_this_round == 1, 'should increment actions');

        table.advance_to_next_player();
        assert(table.current_player_position == 2, 'should advance to 2');
        assert(table.players_acted_this_round == 2, 'should increment actions');

        table.advance_to_next_player();
        assert(table.current_player_position == 0, 'should wrap to 0');
        assert(table.players_acted_this_round == 3, 'should increment actions');
    }

    #[test]
    fn test_is_betting_round_complete() {
        let mut table = TableImpl::new(1, alice(), 10, 20, 400, 2000, 6);

        assert(!table.is_betting_round_complete(3), 'not complete with 0');

        table.players_acted_this_round = 2;
        assert(!table.is_betting_round_complete(3), 'not complete 2/3');

        table.players_acted_this_round = 3;
        assert(table.is_betting_round_complete(3), 'complete with 3/3');

        table.players_acted_this_round = 4;
        assert(table.is_betting_round_complete(3), 'complete with more');
    }

    #[test]
    fn test_advance_round() {
        let mut table = TableImpl::new(1, alice(), 10, 20, 400, 2000, 6);
        table.current_players = 3;
        table.dealer_position = 1;

        // PreFlop -> Flop
        table.current_round = GameRound::PreFlop.into();
        let success1 = table.advance_round();
        assert(success1, 'should advance from preflop');
        assert(table.current_round == GameRound::Flop.into(), 'should be flop');
        assert(table.current_bet == 0, 'should reset bet');
        assert(table.players_acted_this_round == 0, 'should reset actions');
        assert(table.last_raise_amount == 0, 'should reset raise');
        assert(table.current_player_position == 2, 'should set first player');

        // Flop -> Turn
        let success2 = table.advance_round();
        assert(success2, 'should advance from flop');
        assert(table.current_round == GameRound::Turn.into(), 'should be turn');

        // Turn -> River
        let success3 = table.advance_round();
        assert(success3, 'should advance from turn');
        assert(table.current_round == GameRound::River.into(), 'should be river');

        // River -> Showdown
        let success4 = table.advance_round();
        assert(success4, 'should advance from river');
        assert(table.current_round == GameRound::Showdown.into(), 'should be showdown');
        assert(table.status == GameStatus::Showdown.into(), 'status should be showdown');

        // Cannot advance from Showdown
        let fail = table.advance_round();
        assert(!fail, 'should not advance from show');
    }

    #[test]
    fn test_end_game() {
        let mut table = TableImpl::new(1, alice(), 10, 20, 400, 2000, 6);
        table.current_players = 3;
        table.dealer_position = 1;
        table.status = GameStatus::InProgress.into();
        table.current_round = GameRound::River.into();
        table.pot_total = 500;
        table.current_bet = 100;
        table.last_raise_amount = 50;
        table.players_acted_this_round = 3;

        table.end_game();

        assert(table.status == GameStatus::Finished.into(), 'should be finished');
        assert(table.current_round == GameRound::PreFlop.into(), 'should reset to preflop');
        assert(table.dealer_position == 2, 'dealer should move');
        assert(table.pot_total == 0, 'pot should reset');
        assert(table.current_bet == 0, 'bet should reset');
        assert(table.last_raise_amount == 0, 'raise should reset');
        assert(table.players_acted_this_round == 0, 'actions should reset');
    }

    #[test]
    fn test_prepare_next_game() {
        let mut table = TableImpl::new(1, alice(), 10, 20, 400, 2000, 6);
        table.status = GameStatus::Finished.into();

        // Should prepare with enough players
        table.current_players = 2;
        table.prepare_next_game();
        assert(table.status == GameStatus::Waiting.into(), 'should wait with 2');

        // Should not prepare with insufficient players
        table.current_players = 1;
        table.status = GameStatus::Finished.into();
        table.prepare_next_game();
        assert(table.status == GameStatus::Finished.into(), 'should stay finished with 1');
    }

    #[test]
    fn test_get_min_raise() {
        let mut table = TableImpl::new(1, alice(), 10, 20, 400, 2000, 6);

        // PreFlop - should be big blind
        table.current_round = GameRound::PreFlop.into();
        assert(table.get_min_raise() == 20, 'preflop min raise = bb');

        // Post-flop with no raises - should be big blind
        table.current_round = GameRound::Flop.into();
        table.last_raise_amount = 0;
        assert(table.get_min_raise() == 20, 'should be bb no raises');

        // Post-flop with small raise - should be big blind
        table.last_raise_amount = 10;
        assert(table.get_min_raise() == 20, 'should be bb small raise');

        // Post-flop with big raise - should be last raise
        table.last_raise_amount = 50;
        assert(table.get_min_raise() == 50, 'should be last raise');
    }

    #[test]
    fn test_validate_state() {
        let mut table = TableImpl::new(1, alice(), 10, 20, 400, 2000, 6);

        // Valid state
        assert(table.validate_state(), 'new table should be valid');

        // Too many players
        table.current_players = 7;
        assert(!table.validate_state(), 'invalid with too many');

        // Reset and test dealer position
        table.current_players = 3;
        table.dealer_position = 3;
        assert(!table.validate_state(), 'invalid dealer >= players');

        // Reset and test blinds
        table.dealer_position = 0;
        table.big_blind = 5;
        assert(!table.validate_state(), 'invalid bb <= sb');

        // Fix and verify valid
        table.big_blind = 20;
        assert(table.validate_state(), 'should be valid after fix');
    }

    // COMMUNITY CARDS TRAIT TESTS //

    #[test]
    fn test_community_cards_creation() {
        let community = CommunityCardsImpl::new(1, 5);

        assert(community.table_id == 1, 'wrong table id');
        assert(community.game_number == 5, 'wrong game number');
        assert(community.cards_dealt == 0, 'should start with 0');
        assert(community.flop1 == 255, 'flop1 invalid initially');
        assert(community.flop2 == 255, 'flop2 invalid initially');
        assert(community.flop3 == 255, 'flop3 invalid initially');
        assert(community.turn == 255, 'turn invalid initially');
        assert(community.river == 255, 'river invalid initially');
        assert(!community.has_flop(), 'no flop initially');
        assert(!community.has_turn(), 'no turn initially');
        assert(!community.has_river(), 'no river initially');
    }

    #[test]
    fn test_deal_flop() {
        let mut community = CommunityCardsImpl::new(1, 1);

        community.deal_flop(0, 13, 26);

        assert(community.flop1 == 0, 'wrong flop1');
        assert(community.flop2 == 13, 'wrong flop2');
        assert(community.flop3 == 26, 'wrong flop3');
        assert(community.cards_dealt == 3, 'should have 3 dealt');
        assert(community.has_flop(), 'should have flop');
        assert(!community.has_turn(), 'no turn yet');
        assert(!community.has_river(), 'no river yet');
    }

    #[test]
    #[should_panic(expected: ('Flop already dealt',))]
    fn test_deal_flop_twice() {
        let mut community = CommunityCardsImpl::new(1, 1);

        community.deal_flop(0, 13, 26);
        community.deal_flop(1, 14, 27); // Should panic
    }

    #[test]
    #[should_panic(expected: ('Invalid card indices',))]
    fn test_deal_flop_invalid_cards() {
        let mut community = CommunityCardsImpl::new(1, 1);

        community.deal_flop(0, 13, 52); // 52 is invalid
    }

    #[test]
    fn test_deal_turn() {
        let mut community = CommunityCardsImpl::new(1, 1);

        community.deal_flop(0, 13, 26);
        community.deal_turn(39);

        assert(community.turn == 39, 'wrong turn card');
        assert(community.cards_dealt == 4, 'should have 4 dealt');
        assert(community.has_turn(), 'should have turn');
        assert(!community.has_river(), 'no river yet');
    }

    #[test]
    #[should_panic(expected: ('Must deal flop first',))]
    fn test_deal_turn_without_flop() {
        let mut community = CommunityCardsImpl::new(1, 1);

        community.deal_turn(39); // Should panic
    }

    #[test]
    fn test_deal_river() {
        let mut community = CommunityCardsImpl::new(1, 1);

        community.deal_flop(0, 13, 26);
        community.deal_turn(39);
        community.deal_river(51);

        assert(community.river == 51, 'wrong river card');
        assert(community.cards_dealt == 5, 'should have 5 dealt');
        assert(community.has_river(), 'should have river');
    }

    #[test]
    #[should_panic(expected: ('Must deal turn first',))]
    fn test_deal_river_without_turn() {
        let mut community = CommunityCardsImpl::new(1, 1);

        community.deal_flop(0, 13, 26);
        community.deal_river(51); // Should panic
    }

    #[test]
    fn test_get_dealt_cards() {
        let mut community = CommunityCardsImpl::new(1, 1);

        // No cards dealt
        let empty_cards = community.get_dealt_cards();
        assert(empty_cards.len() == 0, 'should have 0 cards');

        // Flop dealt
        community.deal_flop(0, 13, 26);
        let flop_cards = community.get_dealt_cards();
        assert(flop_cards.len() == 3, 'should have 3 cards');
        assert(*flop_cards.at(0) == 0, 'wrong flop card 1');
        assert(*flop_cards.at(1) == 13, 'wrong flop card 2');
        assert(*flop_cards.at(2) == 26, 'wrong flop card 3');

        // Turn dealt
        community.deal_turn(39);
        let turn_cards = community.get_dealt_cards();
        assert(turn_cards.len() == 4, 'should have 4 cards');
        assert(*turn_cards.at(3) == 39, 'wrong turn card');

        // River dealt
        community.deal_river(51);
        let all_cards = community.get_dealt_cards();
        assert(all_cards.len() == 5, 'should have 5 cards');
        assert(*all_cards.at(4) == 51, 'wrong river card');
    }

    #[test]
    fn test_get_all_cards() {
        let mut community = CommunityCardsImpl::new(1, 1);
        community.deal_flop(0, 13, 26);
        community.deal_turn(39);
        community.deal_river(51);

        let all_cards = community.get_all_cards();
        assert(all_cards.len() == 5, 'should have 5 cards');
        assert(*all_cards.at(0) == 0, 'wrong card 0');
        assert(*all_cards.at(1) == 13, 'wrong card 1');
        assert(*all_cards.at(2) == 26, 'wrong card 2');
        assert(*all_cards.at(3) == 39, 'wrong card 3');
        assert(*all_cards.at(4) == 51, 'wrong card 4');
    }

    // GAME DECK TRAIT TESTS //

    #[test]
    fn test_game_deck_creation() {
        let deck_cards = array![0, 1, 2, 3, 4].span();
        let deck = GameDeckImpl::new(1, 1, deck_cards, 12345);

        assert(deck.table_id == 1, 'wrong table id');
        assert(deck.game_number == 1, 'wrong game number');
        assert(deck.next_card_index == 0, 'should start at 0');
        assert(deck.seed == 12345, 'wrong seed');
        assert(deck.cards_remaining() == 52, 'should have 52 remaining');
    }

    #[test]
    fn test_deal_next_card() {
        let deck_cards = array![10, 20, 30, 40, 50].span();
        let mut deck = GameDeckImpl::new(1, 1, deck_cards, 12345);

        let card1 = deck.deal_next_card();
        assert(card1 == 10, 'wrong first card');
        assert(deck.next_card_index == 1, 'index should increment');
        assert(deck.cards_remaining() == 51, 'should have 51 left');

        let card2 = deck.deal_next_card();
        assert(card2 == 20, 'wrong second card');
        assert(deck.next_card_index == 2, 'index should increment');
        assert(deck.cards_remaining() == 50, 'should have 50 left');
    }

    #[test]
    fn test_deal_multiple_cards() {
        let deck_cards = array![10, 20, 30, 40, 50].span();
        let mut deck = GameDeckImpl::new(1, 1, deck_cards, 12345);

        let cards = deck.deal_multiple_cards(3);
        assert(cards.len() == 3, 'should deal 3 cards');
        assert(*cards.at(0) == 10, 'wrong first card');
        assert(*cards.at(1) == 20, 'wrong second card');
        assert(*cards.at(2) == 30, 'wrong third card');
        assert(deck.next_card_index == 3, 'index should be 3');
        assert(deck.cards_remaining() == 49, 'should have 49 left');
    }

    #[test]
    fn test_peek_next_card() {
        let deck_cards = array![10, 20, 30, 40, 50].span();
        let deck = GameDeckImpl::new(1, 1, deck_cards, 12345);

        let peeked = deck.peek_next_card();
        assert(peeked == 10, 'should peek first card');
        assert(deck.next_card_index == 0, 'index should not change');
        assert(deck.cards_remaining() == 52, 'remaining should not change');
    }

    #[test]
    #[should_panic(expected: ('No more cards in deck',))]
    fn test_deal_next_card_empty_deck() {
        // Create a full deck but deal almost all cards
        let mut full_deck: Array<u8> = array![];
        let mut i = 0;
        while i < 52 {
            full_deck.append(i);
            i += 1;
        };

        let mut deck = GameDeckImpl::new(1, 1, full_deck.span(), 12345);

        // Deal all 52 cards
        let mut dealt: u8 = 0;
        while dealt < 52 {
            deck.deal_next_card();
            dealt += 1;
        };

        deck.deal_next_card();
    }

    #[test]
    #[should_panic(expected: ('No more cards in deck',))]
    fn test_peek_next_card_empty_deck() {
        // Create a full deck but deal all cards
        let mut full_deck: Array<u8> = array![];
        let mut i = 0;
        while i < 52 {
            full_deck.append(i);
            i += 1;
        };

        let mut deck = GameDeckImpl::new(1, 1, full_deck.span(), 12345);

        // Deal all 52 cards
        let mut dealt: u8 = 0;
        while dealt < 52 {
            deck.deal_next_card();
            dealt += 1;
        };

        deck.peek_next_card();
    }

    #[test]
    fn test_full_deck_simulation() {
        // Create a full 52-card deck
        let mut full_deck: Array<u8> = array![];
        let mut i = 0;
        while i < 52 {
            full_deck.append(i);
            i += 1;
        };

        let mut deck = GameDeckImpl::new(1, 1, full_deck.span(), 12345);

        // Deal cards and verify they're in order
        let mut dealt_count = 0;
        while dealt_count < 52 {
            let expected_card = dealt_count;
            let actual_card = deck.deal_next_card();
            assert(actual_card == expected_card, 'wrong card order');

            let remaining = deck.cards_remaining();
            assert(remaining == 52 - dealt_count - 1, 'wrong remaining count');

            dealt_count += 1;
        };

        assert(deck.cards_remaining() == 0, 'should have 0 left');
    }

    #[test]
    fn test_full_game_flow_simulation() {
        // Create a table
        let mut table = TableImpl::new(1, alice(), 10, 20, 400, 2000, 6);

        // Add players
        table.add_player();
        table.add_player();

        // Start game
        assert(table.start_game(), 'should start game');

        // Post blinds
        table.post_blinds();
        assert(table.pot_total == 30, 'pot should have blinds');

        // Create deck and community cards
        let mut deck_cards: Array<u8> = array![];
        let mut i = 0;
        while i < 52 {
            deck_cards.append(i);
            i += 1;
        };

        let mut deck = GameDeckImpl::new(1, table.game_number, deck_cards.span(), 12345);
        let mut community = CommunityCardsImpl::new(1, table.game_number);

        // Deal hole cards (4 cards total - 2 per player)
        let hole_cards = deck.deal_multiple_cards(4);
        assert(hole_cards.len() == 4, 'should deal 4 hole cards');

        // Simulate pre-flop betting
        table.add_to_pot(50); // Player actions add to pot
        table.advance_to_next_player();
        table.advance_to_next_player();

        // Advance to flop
        assert(table.advance_round(), 'should advance to flop');

        // Deal flop
        deck.deal_next_card(); // Burn card
        let flop_cards = deck.deal_multiple_cards(3);
        community.deal_flop(*flop_cards.at(0), *flop_cards.at(1), *flop_cards.at(2));
        assert(community.has_flop(), 'should have flop');

        // Simulate flop betting and advance to turn
        assert(table.advance_round(), 'should advance to turn');

        // Deal turn
        deck.deal_next_card(); // Burn card
        let turn_card = deck.deal_next_card();
        community.deal_turn(turn_card);
        assert(community.has_turn(), 'should have turn');

        // Simulate turn betting and advance to river
        assert(table.advance_round(), 'should advance to river');

        // Deal river
        deck.deal_next_card(); // Burn card
        let river_card = deck.deal_next_card();
        community.deal_river(river_card);
        assert(community.has_river(), 'should have river');

        // Advance to showdown
        assert(table.advance_round(), 'should advance to showdown');
        assert(table.current_round == GameRound::Showdown.into(), 'should be showdown');
        assert(table.status == GameStatus::Showdown.into(), 'status should be showdown');

        // End game
        table.end_game();
        assert(table.status == GameStatus::Finished.into(), 'should be finished');
        assert(table.dealer_position == 1, 'dealer should have moved');

        // Verify all community cards are dealt
        let all_community = community.get_dealt_cards();
        assert(all_community.len() == 5, 'should have 5 comm cards');

        // Verify cards are valid
        let mut j = 0;
        while j < all_community.len() {
            assert(*all_community.at(j) < 52, 'all cards should be valid');
            j += 1;
        };
    }

    #[test]
    fn test_table_with_different_player_counts() {
        // Test 2 players
        let mut table2 = TableImpl::new(1, alice(), 5, 10, 200, 1000, 6);
        table2.current_players = 2;
        table2.dealer_position = 0;

        let next2 = table2.get_next_position_after_blinds();
        assert(next2 == 1, 'in 2p pos 1 acts first');

        // Test 3 players
        let mut table3 = TableImpl::new(2, bob(), 5, 10, 200, 1000, 6);
        table3.current_players = 3;
        table3.dealer_position = 1;

        let next3 = table3.get_next_position_after_blinds();
        assert(next3 == 1, 'in 3p (1+3)%3 = 1');

        // Test 6 players
        let mut table6 = TableImpl::new(3, charlie(), 5, 10, 200, 1000, 6);
        table6.current_players = 6;
        table6.dealer_position = 2;

        let next6 = table6.get_next_position_after_blinds();
        assert(next6 == 5, 'in 6p (2+3)%6 = 5');
    }

    #[test]
    fn test_dealer_button_rotation() {
        let mut table = TableImpl::new(1, alice(), 10, 20, 400, 2000, 6);
        table.current_players = 4;

        // Start at position 0
        assert(table.dealer_position == 0, 'should start at 0');

        // End game - dealer should move
        table.end_game();
        assert(table.dealer_position == 1, 'should move to 1');

        // End another game
        table.end_game();
        assert(table.dealer_position == 2, 'should move to 2');

        // Test wrap-around
        table.dealer_position = 3;
        table.end_game();
        assert(table.dealer_position == 0, 'should wrap to 0');
    }

    #[test]
    fn test_betting_state_reset() {
        let mut table = TableImpl::new(1, alice(), 10, 20, 400, 2000, 6);
        table.current_players = 3;
        table.dealer_position = 1;

        // Set some betting state
        table.current_bet = 100;
        table.last_raise_amount = 50;
        table.players_acted_this_round = 2;
        table.current_player_position = 2;

        // Reset betting round
        table.reset_betting_round();

        assert(table.current_bet == 0, 'bet should reset');
        assert(table.last_raise_amount == 0, 'raise should reset');
        assert(table.players_acted_this_round == 0, 'actions should reset');
        assert(table.current_player_position == 2, 'should set first player');
    }

    #[test]
    fn test_community_cards_edge_cases() {
        let mut community = CommunityCardsImpl::new(1, 1);

        // Test get_dealt_cards at each stage
        let empty = community.get_dealt_cards();
        assert(empty.len() == 0, 'should be empty initially');

        community.deal_flop(0, 1, 2);
        let flop_only = community.get_dealt_cards();
        assert(flop_only.len() == 3, 'should have flop only');

        community.deal_turn(3);
        let with_turn = community.get_dealt_cards();
        assert(with_turn.len() == 4, 'should have flop + turn');

        community.deal_river(4);
        let complete = community.get_dealt_cards();
        assert(complete.len() == 5, 'should have all cards');

        // Verify order is maintained
        assert(*complete.at(0) == 0, 'wrong flop1');
        assert(*complete.at(1) == 1, 'wrong flop2');
        assert(*complete.at(2) == 2, 'wrong flop3');
        assert(*complete.at(3) == 3, 'wrong turn');
        assert(*complete.at(4) == 4, 'wrong river');
    }

    #[test]
    fn test_deck_with_custom_order() {
        // Test deck with specific card order
        let custom_cards = array![51, 25, 0, 13, 39].span(); // A♠, K♥, 2♠, 2♥, A♦
        let mut deck = GameDeckImpl::new(1, 1, custom_cards, 54321);

        assert(deck.peek_next_card() == 51, 'should peek ace of spades');

        let first = deck.deal_next_card();
        assert(first == 51, 'should deal ace of spades');

        let second = deck.deal_next_card();
        assert(second == 25, 'should deal king of hearts');

        let remaining_cards = deck.deal_multiple_cards(3);
        assert(*remaining_cards.at(0) == 0, 'wrong third card');
        assert(*remaining_cards.at(1) == 13, 'wrong fourth card');
        assert(*remaining_cards.at(2) == 39, 'wrong fifth card');

        assert(deck.cards_remaining() == 47, 'should have 47 left');
    }

    #[test]
    fn test_table_state_consistency() {
        let mut table = TableImpl::new(1, alice(), 10, 20, 400, 2000, 6);

        // Test state consistency throughout game flow
        assert(table.validate_state(), 'should be valid initially');

        table.add_player();
        table.add_player();
        assert(table.validate_state(), 'should be valid after add');

        table.start_game();
        assert(table.validate_state(), 'should be valid after start');

        table.post_blinds();
        assert(table.validate_state(), 'should be valid after blinds');

        table.advance_round();
        assert(table.validate_state(), 'should be valid after round');

        table.end_game();
        assert(table.validate_state(), 'should be valid after end');
    }
}
