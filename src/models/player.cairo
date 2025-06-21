use starknet::{ContractAddress};
use poker_game::models::card::{Card, CardTrait, CardRank, CardSuits};

#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
struct Player {
    #[key]
    address: ContractAddress,
    #[key]
    table_id: u32,
    stack: u128,
    current_bet: u128,
    hole_card1: u8, // card index (0-51)
    hole_card2: u8, // card index (0-51)
    is_active: bool,
    has_acted: bool,
    position: u8,
    // PlayerAction
    last_action: felt252,
}

#[derive(Copy, Drop, Serde, PartialEq, Introspect)]
enum PlayerAction {
    Check,
    Call,
    Raise,
    Fold,
    AllIn,
}

impl PlayerActionIntoFelt252 of Into<PlayerAction, felt252> {
    fn into(self: PlayerAction) -> felt252 {
        match self {
            PlayerAction::Check => 'CHECK',
            PlayerAction::Call => 'CALL',
            PlayerAction::Raise => 'RAISE',
            PlayerAction::Fold => 'FOLD',
            PlayerAction::AllIn => 'ALL_IN',
        }
    }
}

impl Felt252TryIntoPlayerAction of TryInto<felt252, PlayerAction> {
    fn try_into(self: felt252) -> Option<PlayerAction> {
        if self == 'CHECK' {
            Option::Some(PlayerAction::Check)
        } else if self == 'CALL' {
            Option::Some(PlayerAction::Call)
        } else if self == 'RAISE' {
            Option::Some(PlayerAction::Raise)
        } else if self == 'FOLD' {
            Option::Some(PlayerAction::Fold)
        } else if self == 'ALL_IN' {
            Option::Some(PlayerAction::AllIn)
        } else {
            Option::None
        }
    }
}


#[generate_trait]
pub impl PlayerImpl of PlayerTrait {
    fn new(address: ContractAddress, table_id: u32, stack: u128, position: u8) -> Player {
        Player {
            address,
            table_id,
            stack,
            current_bet: 0,
            hole_card1: 255, // Invalid index until cards are dealt
            hole_card2: 255,
            is_active: true,
            has_acted: false,
            position,
            last_action: PlayerAction::Check.into() // Default action
        }
    }

    /// Deal hole cards to the player
    fn deal_hole_cards(ref self: Player, card1: u8, card2: u8) {
        assert(card1 < 52 && card2 < 52, 'Invalid card indices');
        assert(card1 != card2, 'Cannot deal same card twice');

        self.hole_card1 = card1;
        self.hole_card2 = card2;
    }

    /// Get player's hole cards as Cards
    fn get_hole_cards(self: @Player) -> (Card, Card) {
        assert(*self.hole_card1 < 52 && *self.hole_card2 < 52, 'No cards dealt');

        (CardTrait::from_index(*self.hole_card1), CardTrait::from_index(*self.hole_card2))
    }

    /// Check if player has been dealt cards
    fn has_hole_cards(self: @Player) -> bool {
        *self.hole_card1 < 52 && *self.hole_card2 < 52
    }

    /// Place a bet (updates stack and current_bet)
    fn place_bet(ref self: Player, amount: u128) -> bool {
        if amount > self.stack {
            return false; // Insufficient funds
        }

        self.stack -= amount;
        self.current_bet += amount;
        self.has_acted = true;
        true
    }

    /// Go all-in with remaining stack
    fn go_all_in(ref self: Player) -> u128 {
        let all_in_amount = self.stack;
        self.current_bet += all_in_amount;
        self.stack = 0;
        self.has_acted = true;
        self.last_action = PlayerAction::AllIn.into();
        all_in_amount
    }

    /// Fold the hand
    fn fold(ref self: Player) {
        self.is_active = false;
        self.has_acted = true;
        self.last_action = PlayerAction::Fold.into();
    }

    /// Check (no additional bet required)
    fn check(ref self: Player) {
        self.has_acted = true;
        self.last_action = PlayerAction::Check.into();
    }

    /// Call a bet (match the current table bet)
    fn call(ref self: Player, table_bet: u128) -> bool {
        let call_amount = table_bet - self.current_bet;

        if call_amount > self.stack {
            // Not enough for full call - go all-in instead
            self.go_all_in();
            return false;
        }

        if self.place_bet(call_amount) {
            self.last_action = PlayerAction::Call.into();
            true
        } else {
            false
        }
    }

    /// Raise (increase the bet)
    fn raise(ref self: Player, raise_amount: u128, current_table_bet: u128) -> bool {
        let total_bet = current_table_bet + raise_amount;
        let additional_amount = total_bet - self.current_bet;

        if additional_amount > self.stack {
            return false; // Insufficient funds
        }

        if self.place_bet(additional_amount) {
            self.last_action = PlayerAction::Raise.into();
            true
        } else {
            false
        }
    }

    /// Check if player can perform a specific action
    fn can_perform_action(
        self: @Player, action: PlayerAction, table_bet: u128, min_raise: u128,
    ) -> bool {
        if !*self.is_active {
            return false; // Folded players can't act
        }

        match action {
            PlayerAction::Fold => true, // Can always fold
            PlayerAction::Check => *self.current_bet == table_bet, // Can check if no bet to call
            PlayerAction::Call => {
                let call_amount = table_bet - *self.current_bet;
                call_amount > 0 && call_amount <= *self.stack
            },
            PlayerAction::Raise => {
                let total_raise = table_bet + min_raise;
                let additional_needed = total_raise - *self.current_bet;
                additional_needed <= *self.stack
            },
            PlayerAction::AllIn => *self.stack > 0,
        }
    }

    /// Get amount needed to call current bet
    fn get_call_amount(self: @Player, table_bet: u128) -> u128 {
        if table_bet > *self.current_bet {
            table_bet - *self.current_bet
        } else {
            0
        }
    }

    /// Check if player is all-in
    fn is_all_in(self: @Player) -> bool {
        *self.stack == 0 && *self.current_bet > 0
    }

    /// Get player's total commitment to pot
    fn get_total_pot_commitment(self: @Player) -> u128 {
        *self.current_bet
    }

    /// Reset for new betting round
    fn reset_for_new_round(ref self: Player) {
        self.current_bet = 0;
        self.has_acted = false;
        self.last_action = PlayerAction::Check.into();
        // folded players stay folded, so resetting is_active
    // No resetting of stack or hole cards
    }

    /// Get player's hole cards combined with community cards for evaluation
    fn get_all_cards_for_evaluation(self: @Player, community_cards: Span<u8>) -> Array<Card> {
        assert(self.has_hole_cards(), 'Player has no hole cards');

        let mut all_cards: Array<Card> = array![];

        // Add hole cards
        let (hole1, hole2) = self.get_hole_cards();
        all_cards.append(hole1);
        all_cards.append(hole2);

        // Add community cards
        let mut i = 0;
        while i < community_cards.len() {
            let card = CardTrait::from_index(*community_cards.at(i));
            all_cards.append(card);
            i += 1;
        };

        all_cards
    }

    /// Get readable representation of player's action
    fn get_last_action(self: @Player) -> felt252 {
        *self.last_action
    }

    /// Check if player is small blind
    fn is_small_blind(self: @Player, dealer_position: u8, total_players: u8) -> bool {
        let sb_position = if total_players == 2 {
            dealer_position // Heads-up: dealer is small blind
        } else {
            (dealer_position + 1) % total_players // 3+ players: next after dealer
        };
        *self.position == sb_position
    }

    /// Check if player is big blind
    fn is_big_blind(self: @Player, dealer_position: u8, total_players: u8) -> bool {
        let bb_position = if total_players == 2 {
            (dealer_position + 1) % total_players // Heads-up: non-dealer is big blind
        } else {
            (dealer_position + 2) % total_players // 3+ players: two after dealer
        };
        *self.position == bb_position
    }

    /// Check if player is in specific position relative to dealer
    fn is_in_position(
        self: @Player, dealer_position: u8, target_position: u8, total_players: u8,
    ) -> bool {
        let expected_pos = (dealer_position + target_position) % total_players;
        *self.position == expected_pos
    }

    /// Check if player is the dealer
    fn is_dealer(self: @Player, dealer_position: u8) -> bool {
        *self.position == dealer_position
    }

    /// Get player's position name
    fn get_position_name(self: @Player, dealer_position: u8, total_players: u8) -> felt252 {
        if self.is_dealer(dealer_position) {
            'DEALER'
        } else if self.is_small_blind(dealer_position, total_players) {
            'SMALL_BLIND'
        } else if self.is_big_blind(dealer_position, total_players) {
            'BIG_BLIND'
        } else {
            'PLAYER'
        }
    }

    /// Check if this player should act first pre-flop
    fn should_act_first_preflop(self: @Player, dealer_position: u8, total_players: u8) -> bool {
        let first_to_act = if total_players == 2 {
            dealer_position // Heads-up: dealer acts first pre-flop
        } else {
            (dealer_position + 3) % total_players // 3+ players: after big blind
        };
        *self.position == first_to_act
    }

    /// Check if this player should act first post-flop
    fn should_act_first_postflop(self: @Player, dealer_position: u8, total_players: u8) -> bool {
        let first_to_act = (dealer_position + 1) % total_players;
        *self.position == first_to_act && *self.is_active
    }

    /// Post blind (small or big)
    fn post_blind(ref self: Player, blind_amount: u128) -> bool {
        if blind_amount > self.stack {
            // Post whatever they have left
            let posted = self.stack;
            self.current_bet = posted;
            self.stack = 0;
            return false; // Couldn't post full blind
        }

        self.stack -= blind_amount;
        self.current_bet = blind_amount;
        true
    }

    fn validate_state(self: @Player) -> bool {
        // Basic validations
        if *self.position > 9 { // Max 10 players
            return false;
        }

        if *self.hole_card1 < 52 && *self.hole_card2 < 52 && *self.hole_card1 == *self.hole_card2 {
            return false; // Same card twice
        }

        // If folded, should not be acting
        if !*self.is_active
            && *self.has_acted { // This is actually valid - folded players have acted
        }

        true
    }
}

#[cfg(test)]
mod player_tests {
    use super::*;
    use starknet::{contract_address_const, ContractAddress};

    // Test addresses
    fn get_test_address() -> ContractAddress {
        contract_address_const::<0x1234>()
    }

    fn get_test_address_2() -> ContractAddress {
        contract_address_const::<0x5678>()
    }

    fn player(val: felt252) -> ContractAddress {
        val.try_into().unwrap()
    }

    #[test]
    fn test_player_creation() {
        let player = PlayerTrait::new(
            get_test_address(), 1, // table_id
            1000, // stack
            0 // position
        );

        assert(player.address == get_test_address(), 'Wrong address');
        assert(player.table_id == 1, 'Wrong table_id');
        assert(player.stack == 1000, 'Wrong stack');
        assert(player.current_bet == 0, 'Current bet should be 0');
        assert(player.is_active, 'Should be active');
        assert(!player.has_acted, 'Should not have acted');
        assert(player.position == 0, 'Wrong position');
        assert(!player.has_hole_cards(), 'Should not have cards initially');
    }

    #[test]
    fn test_deal_hole_cards() {
        let mut player = PlayerTrait::new(get_test_address(), 1, 1000, 0);

        // Deal cards
        player.deal_hole_cards(0, 13); // Two of Spades, Two of Hearts

        assert(player.has_hole_cards(), 'Should have hole cards');
        assert(player.hole_card1 == 0, 'Wrong first card');
        assert(player.hole_card2 == 13, 'Wrong second card');

        // Test getting cards back
        let (card1, card2) = player.get_hole_cards();
        assert(card1.rank == CardRank::Two, 'Wrong first card rank');
        assert(card1.suit == CardSuits::Spades, 'Wrong first card suit');
        assert(card2.rank == CardRank::Two, 'Wrong second card rank');
        assert(card2.suit == CardSuits::Hearts, 'Wrong second card suit');
    }

    #[test]
    #[should_panic(expected: ('Cannot deal same card twice',))]
    fn test_deal_same_card_twice() {
        let mut player = PlayerTrait::new(get_test_address(), 1, 1000, 0);
        player.deal_hole_cards(0, 0); // Same card twice - should panic
    }

    #[test]
    #[should_panic(expected: ('Invalid card indices',))]
    fn test_deal_invalid_cards() {
        let mut player = PlayerTrait::new(get_test_address(), 1, 1000, 0);
        player.deal_hole_cards(52, 1); // Invalid card index - should panic
    }

    #[test]
    fn test_basic_betting() {
        let mut player = PlayerTrait::new(get_test_address(), 1, 1000, 0);

        // Place a bet
        let success = player.place_bet(100);
        assert(success, 'Bet should succeed');
        assert(player.stack == 900, 'Stack should decrease');
        assert(player.current_bet == 100, 'Current bet should increase');
        assert(player.has_acted, 'Should have acted');

        // Try to bet more than stack
        let fail = player.place_bet(1000);
        assert(!fail, 'Bet should fail');
        assert(player.stack == 900, 'Stack should not change');
    }

    #[test]
    fn test_all_in() {
        let mut player = PlayerTrait::new(get_test_address(), 1, 500, 0);

        let all_in_amount = player.go_all_in();
        assert(all_in_amount == 500, 'Wrong all-in amount');
        assert(player.stack == 0, 'Stack should be 0');
        assert!(player.current_bet == 500, "Current bet should be all-in amount");
        assert(player.has_acted, 'Should have acted');
        assert(player.is_all_in(), 'Should be all-in');

        let action: PlayerAction = (player.last_action).try_into().unwrap();
        assert(action == PlayerAction::AllIn, 'Last action should be AllIn');
    }

    #[test]
    fn test_fold() {
        let mut player = PlayerTrait::new(get_test_address(), 1, 1000, 0);

        player.fold();
        assert(!player.is_active, 'Should not be active');
        assert(player.has_acted, 'Should have acted');

        let action: PlayerAction = (player.last_action).try_into().unwrap();
        assert(action == PlayerAction::Fold, 'Last action should be Fold');
    }

    #[test]
    fn test_check() {
        let mut player = PlayerTrait::new(get_test_address(), 1, 1000, 0);

        player.check();
        assert(player.has_acted, 'Should have acted');
        assert(player.stack == 1000, 'Stack should not change');
        assert(player.current_bet == 0, 'Current bet should not change');

        let action: PlayerAction = (player.last_action).try_into().unwrap();
        assert(action == PlayerAction::Check, 'Last action should be Check');
    }

    #[test]
    fn test_call() {
        let mut player = PlayerTrait::new(get_test_address(), 1, 1000, 0);

        // First, place a small bet
        player.place_bet(50);

        // Now call a bet of 200 (need to add 150 more)
        let success = player.call(200);
        assert(success, 'Call should succeed');
        assert(player.stack == 800, 'Stack should be 800 (1000-200)');
        assert(player.current_bet == 200, 'Current bet should be 200');

        let action: PlayerAction = (player.last_action).try_into().unwrap();
        assert(action == PlayerAction::Call, 'Last action should be Call');
    }

    #[test]
    fn test_call_insufficient_funds() {
        let mut player = PlayerTrait::new(get_test_address(), 1, 100, 0);

        // Try to call a bet larger than stack
        let success = player.call(500);
        assert!(!success, "Call should fail due to insufficient funds");

        // Should go all-in instead
        assert(player.stack == 0, 'Should be all-in');
        assert(player.current_bet == 100, 'Should bet entire stack');
    }

    #[test]
    fn test_raise() {
        let mut player = PlayerTrait::new(get_test_address(), 1, 1000, 0);

        // Current table bet is 100, raise by 50 (total 150)
        let success = player.raise(50, 100);
        assert(success, 'Raise should succeed');
        assert(player.stack == 850, 'Stack should be 850 (1000-150)');
        assert(player.current_bet == 150, 'Current bet should be 150');

        let action: PlayerAction = (player.last_action).try_into().unwrap();
        assert(action == PlayerAction::Raise, 'Last action should be Raise');
    }

    #[test]
    fn test_can_perform_actions() {
        let mut player = PlayerTrait::new(get_test_address(), 1, 1000, 0);

        // Can always fold
        assert(player.can_perform_action(PlayerAction::Fold, 0, 0), 'Should be able to fold');

        // Can check when no bet to call
        assert(player.can_perform_action(PlayerAction::Check, 0, 0), 'Should be able to check');

        // Cannot check when there's a bet to call
        assert!(
            !player.can_perform_action(PlayerAction::Check, 100, 0),
            "Should not be able to check with bet",
        );

        // Can call if have enough funds
        assert(player.can_perform_action(PlayerAction::Call, 100, 0), 'Should be able to call');

        // Can raise if have enough funds
        assert(player.can_perform_action(PlayerAction::Raise, 100, 50), 'Should be able to raise');

        // Can go all-in if have chips
        assert(player.can_perform_action(PlayerAction::AllIn, 0, 0), 'Should be able to go all-in');
    }

    #[test]
    fn test_folded_player_cannot_act() {
        let mut player = PlayerTrait::new(get_test_address(), 1, 1000, 0);

        player.fold();

        // Folded players cannot perform any actions
        assert(!player.can_perform_action(PlayerAction::Check, 0, 0), 'Folded player cannot check');
        assert(!player.can_perform_action(PlayerAction::Call, 100, 0), 'Folded player cannot call');
        assert(
            !player.can_perform_action(PlayerAction::Raise, 100, 50), 'Folded player cannot raise',
        );
        assert(
            !player.can_perform_action(PlayerAction::AllIn, 0, 0), 'Folded player cannot go all-in',
        );
    }

    #[test]
    fn test_get_call_amount() {
        let mut player = PlayerTrait::new(get_test_address(), 1, 1000, 0);

        // No current bet, table bet is 100
        assert(player.get_call_amount(100) == 100, 'Should need to call 100');

        // Place a bet of 50
        player.place_bet(50);

        // Now only need to call 50 more to match table bet of 100
        assert(player.get_call_amount(100) == 50, 'Should need to call 50 more');

        // If current bet equals table bet, no call needed
        assert!(player.get_call_amount(50) == 0, "Should not need to call anything");
    }

    #[test]
    fn test_position_helpers() {
        // Test with 6 players
        let sb_player = PlayerTrait::new(get_test_address(), 1, 1000, 1);
        let bb_player = PlayerTrait::new(get_test_address_2(), 1, 1000, 2);

        // With dealer at position 0, position 1 is small blind (for 6 players)
        assert!(sb_player.is_small_blind(0, 6), "Position 1 should be small blind in 6-handed");
        assert!(!sb_player.is_big_blind(0, 6), "Position 1 should not be big blind");

        assert!(bb_player.is_big_blind(0, 6), "Position 2 should be big blind in 6-handed");
        assert!(!bb_player.is_small_blind(0, 6), "Position 2 should not be small blind");

        // Test heads-up separately
        let dealer = PlayerTrait::new(get_test_address(), 1, 1000, 0);
        let non_dealer = PlayerTrait::new(get_test_address_2(), 1, 1000, 1);

        assert!(dealer.is_small_blind(0, 2), "Dealer should be SB in heads-up");
        assert!(non_dealer.is_big_blind(0, 2), "Non-dealer should be BB in heads-up");
    }

    #[test]
    fn test_post_blinds() {
        let mut sb_player = PlayerTrait::new(get_test_address(), 1, 1000, 1);
        let mut bb_player = PlayerTrait::new(get_test_address_2(), 1, 1000, 2);

        // Post small blind (10)
        let sb_success = sb_player.post_blind(10);
        assert(sb_success, 'Small blind should be posted');
        assert(sb_player.stack == 990, 'SB stack should decrease');
        assert(sb_player.current_bet == 10, 'SB current bet should be 10');

        // Post big blind (20)
        let bb_success = bb_player.post_blind(20);
        assert(bb_success, 'Big blind should be posted');
        assert(bb_player.stack == 980, 'BB stack should decrease');
        assert(bb_player.current_bet == 20, 'BB current bet should be 20');
    }

    #[test]
    fn test_reset_for_new_round() {
        let mut player = PlayerTrait::new(get_test_address(), 1, 1000, 0);

        // Make some actions
        player.place_bet(100);
        player.check();

        assert(player.current_bet == 100, 'Should have current bet');
        assert(player.has_acted, 'Should have acted');

        // Reset for new round
        player.reset_for_new_round();

        assert(player.current_bet == 0, 'Current bet should be reset');
        assert(!player.has_acted, 'Has acted should be reset');
        assert(player.stack == 900, 'Stack should not be reset');
        assert(player.is_active, 'Should still be active');
    }

    #[test]
    fn test_player_validation() {
        let player = PlayerTrait::new(get_test_address(), 1, 1000, 0);
        assert!(player.validate_state(), "Valid player should pass validation");

        // Test invalid position
        let invalid_player = Player {
            address: get_test_address(),
            table_id: 1,
            stack: 1000,
            current_bet: 0,
            hole_card1: 255,
            hole_card2: 255,
            is_active: true,
            has_acted: false,
            position: 15, // Invalid position > 9
            last_action: PlayerAction::Check.into(),
        };
        assert!(!invalid_player.validate_state(), "Invalid position should fail validation");
    }

    #[test]
    fn test_player_action_conversions() {
        let check: felt252 = PlayerAction::Check.into();
        assert(check == 'CHECK', 'Check conversion failed');

        let call: felt252 = PlayerAction::Call.into();
        assert(call == 'CALL', 'Call conversion failed');

        let raise: felt252 = PlayerAction::Raise.into();
        assert(raise == 'RAISE', 'Raise conversion failed');

        let fold: felt252 = PlayerAction::Fold.into();
        assert(fold == 'FOLD', 'Fold conversion failed');

        let all_in: felt252 = PlayerAction::AllIn.into();
        assert(all_in == 'ALL_IN', 'AllIn conversion failed');

        // Test reverse conversions
        let back_to_check: PlayerAction = 'CHECK'.try_into().unwrap();
        assert(back_to_check == PlayerAction::Check, 'Check reverse conversion failed');

        let back_to_call: PlayerAction = 'CALL'.try_into().unwrap();
        assert(back_to_call == PlayerAction::Call, 'Call reverse conversion failed');
    }

    #[test]
    fn test_heads_up_positions() {
        // Test heads-up (2 players)
        let dealer = PlayerTrait::new(get_test_address(), 1, 1000, 0);
        let non_dealer = PlayerTrait::new(get_test_address_2(), 1, 1000, 1);

        let dealer_pos = 0;
        let total_players = 2;

        // In heads-up: dealer is small blind
        assert!(
            dealer.is_small_blind(dealer_pos, total_players), "Dealer should be SB in heads-up",
        );
        assert!(
            !dealer.is_big_blind(dealer_pos, total_players), "Dealer should not be BB in heads-up",
        );

        // Non-dealer is big blind
        assert!(
            !non_dealer.is_small_blind(dealer_pos, total_players), "Non-dealer should not be SB",
        );
        assert!(
            non_dealer.is_big_blind(dealer_pos, total_players),
            "Non-dealer should be BB in heads-up",
        );

        // Pre-flop action: dealer acts first in heads-up
        assert!(
            dealer.should_act_first_preflop(dealer_pos, total_players),
            "Dealer acts first preflop in heads-up",
        );
        assert!(
            !non_dealer.should_act_first_preflop(dealer_pos, total_players),
            "Non-dealer doesn't act first preflop",
        );

        // Post-flop action: non-dealer acts first
        assert!(
            non_dealer.should_act_first_postflop(dealer_pos, total_players),
            "Non-dealer acts first postflop",
        );
        assert!(
            !dealer.should_act_first_postflop(dealer_pos, total_players),
            "Dealer doesn't act first postflop",
        );
    }

    #[test]
    fn test_six_handed_positions() {
        let dealer = PlayerTrait::new(player('one'), 1, 1000, 0);
        let sb_player = PlayerTrait::new(player('two'), 1, 1000, 1);
        let bb_player = PlayerTrait::new(player('three'), 1, 1000, 2);
        let utg_player = PlayerTrait::new(player('four'), 1, 1000, 3);

        let dealer_pos = 0;
        let total_players = 6;

        // Test dealer
        assert!(dealer.is_dealer(dealer_pos), "Position 0 should be dealer");
        assert!(
            !dealer.is_small_blind(dealer_pos, total_players),
            "Dealer should not be SB in 6-handed",
        );
        assert!(
            !dealer.is_big_blind(dealer_pos, total_players), "Dealer should not be BB in 6-handed",
        );

        // Test small blind
        assert!(
            sb_player.is_small_blind(dealer_pos, total_players),
            "Position 1 should be SB in 6-handed",
        );
        assert!(!sb_player.is_big_blind(dealer_pos, total_players), "Position 1 should not be BB");
        assert!(!sb_player.is_dealer(dealer_pos), "Position 1 should not be dealer");

        // Test big blind
        assert!(
            !bb_player.is_small_blind(dealer_pos, total_players), "Position 2 should not be SB",
        );
        assert!(
            bb_player.is_big_blind(dealer_pos, total_players),
            "Position 2 should be BB in 6-handed",
        );
        assert!(!bb_player.is_dealer(dealer_pos), "Position 2 should not be dealer");

        // Test UTG (first to act pre-flop)
        assert!(
            utg_player.should_act_first_preflop(dealer_pos, total_players),
            "Position 3 should act first preflop",
        );
        assert!(
            !utg_player.should_act_first_postflop(dealer_pos, total_players),
            "UTG doesn't act first postflop",
        );

        // Post-flop: SB acts first
        assert!(
            sb_player.should_act_first_postflop(dealer_pos, total_players),
            "SB acts first postflop",
        );
    }

    #[test]
    fn test_three_handed_positions() {
        let dealer = PlayerTrait::new(player('dealer'), 1, 1000, 0);
        let sb_player = PlayerTrait::new(player('sb'), 1, 1000, 1);
        let bb_player = PlayerTrait::new(player('bb'), 1, 1000, 2);

        let dealer_pos = 0;
        let total_players = 3;

        // In 3-handed: dealer, SB, BB
        assert!(dealer.is_dealer(dealer_pos), "Position 0 should be dealer");
        assert!(sb_player.is_small_blind(dealer_pos, total_players), "Position 1 should be SB");
        assert!(bb_player.is_big_blind(dealer_pos, total_players), "Position 2 should be BB");

        // Pre-flop: dealer acts first in 3-handed
        assert!(
            dealer.should_act_first_preflop(dealer_pos, total_players),
            "Dealer acts first in 3-handed preflop",
        );

        // Post-flop: SB acts first
        assert!(
            sb_player.should_act_first_postflop(dealer_pos, total_players),
            "SB acts first postflop",
        );
    }

    #[test]
    fn test_position_names() {
        let dealer = PlayerTrait::new(player('dealer'), 1, 1000, 0);
        let sb_player = PlayerTrait::new(player('sb'), 1, 1000, 1);
        let bb_player = PlayerTrait::new(player('bb'), 1, 1000, 2);

        let dealer_pos = 0;
        let total_players = 6;

        assert!(
            dealer.get_position_name(dealer_pos, total_players) == 'DEALER',
            "Should get DEALER name",
        );
        assert!(
            sb_player.get_position_name(dealer_pos, total_players) == 'SMALL_BLIND',
            "Should get SMALL_BLIND name",
        );
        assert!(
            bb_player.get_position_name(dealer_pos, total_players) == 'BIG_BLIND',
            "Should get BIG_BLIND name",
        );
    }

    #[test]
    fn test_dealer_button_movement() {
        let player_pos_1 = PlayerTrait::new(get_test_address(), 1, 1000, 1);

        // When dealer is at 0, position 1 is SB
        assert!(player_pos_1.is_small_blind(0, 6), "Pos 1 should be SB when dealer at 0");

        // When dealer moves to 1, position 1 becomes dealer
        assert!(player_pos_1.is_dealer(1), "Pos 1 should be dealer when dealer at 1");
        assert!(!player_pos_1.is_small_blind(1, 6), "Pos 1 should not be SB when dealer at 1");

        // When dealer moves to 5, position 1 becomes BB (0=SB, 1=BB)
        assert!(player_pos_1.is_big_blind(5, 6), "Pos 1 should be BB when dealer at 5");
    }
}
