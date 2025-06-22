use starknet::ContractAddress;
use pojo::models::player::PlayerAction;

#[starknet::interface]
pub trait IGameSystems<T> {
    // Card dealing
    fn deal_hole_cards(ref self: T, table_id: u32);
    fn deal_flop(ref self: T, table_id: u32);
    fn deal_turn(ref self: T, table_id: u32);
    fn deal_river(ref self: T, table_id: u32);

    // Player actions
    fn player_action(ref self: T, table_id: u32, action: PlayerAction, amount: u128);

    // Betting round management
    fn advance_betting_round(ref self: T, table_id: u32);
    fn check_round_complete(self: @T, table_id: u32) -> bool;

    // Hand evaluation and showdown
    fn evaluate_hands(ref self: T, table_id: u32);
    fn distribute_pot(ref self: T, table_id: u32);

    // Deck management
    fn shuffle_deck(ref self: T, table_id: u32, seed: felt252);

    // Game state queries
    fn get_current_bet(self: @T, table_id: u32) -> u128;
    fn get_active_players(self: @T, table_id: u32) -> Array<ContractAddress>;
    fn get_player_to_act(self: @T, table_id: u32) -> ContractAddress;
    fn can_player_act(self: @T, table_id: u32, player: ContractAddress) -> bool;

    // Post blinds
    fn post_blinds(ref self: T, table_id: u32);
}

#[dojo::contract]
pub mod game_systems {
    use super::*;
    use starknet::{ContractAddress, get_caller_address};
    use pojo::models::table::{
        Table, TableTrait, TablePlayers, TablePlayersTrait, GameStatus, GameRound, GameDeck,
        GameDeckTrait, CommunityCards, CommunityCardsTrait,
    };
    use pojo::models::player::{Player, PlayerTrait, PlayerAction};
    use pojo::models::card::{Card, CardTrait};
    use pojo::constants::{DECK_SIZE};

    use dojo::model::{ModelStorage};
    use dojo::event::EventStorage;
    use origami_random::deck::DeckTrait;

    // Events
    #[derive(Drop, Copy, Serde)]
    #[dojo::event]
    pub struct HoleCardsDealt {
        #[key]
        pub table_id: u32,
        #[key]
        pub game_number: u32,
        pub player_count: u8,
    }

    #[derive(Drop, Copy, Serde)]
    #[dojo::event]
    pub struct CommunityCardsDealt {
        #[key]
        pub table_id: u32,
        #[key]
        pub game_number: u32,
        pub round: felt252,
        pub cards_dealt: u8,
    }

    #[derive(Drop, Copy, Serde)]
    #[dojo::event]
    pub struct PlayerActed {
        #[key]
        pub table_id: u32,
        #[key]
        pub player: ContractAddress,
        pub action: felt252,
        pub amount: u128,
        pub pot_total: u128,
    }

    #[derive(Drop, Copy, Serde)]
    #[dojo::event]
    pub struct BettingRoundComplete {
        #[key]
        pub table_id: u32,
        pub round: felt252,
        pub pot_total: u128,
    }

    #[derive(Drop, Copy, Serde)]
    #[dojo::event]
    pub struct PotDistributed {
        #[key]
        pub table_id: u32,
        #[key]
        pub winner: ContractAddress,
        pub amount: u128,
        pub hand_rank: u8,
    }

    #[derive(Drop, Copy, Serde)]
    #[dojo::event]
    pub struct BlindsPosted {
        #[key]
        pub table_id: u32,
        pub small_blind_player: ContractAddress,
        pub big_blind_player: ContractAddress,
        pub small_blind_amount: u128,
        pub big_blind_amount: u128,
    }

    #[abi(embed_v0)]
    impl GameSystemsImpl of IGameSystems<ContractState> {
        fn shuffle_deck(ref self: ContractState, table_id: u32, seed: felt252) {
            let mut world = self.world_default();
            let table: Table = world.read_model(table_id);

            // Validate game state
            assert(table.status == GameStatus::InProgress.into(), 'Game not in progress');

            // Create shuffled deck
            let shuffled_cards = self.create_shuffled_deck(seed);
            let deck = GameDeckTrait::new(table_id, table.game_number, shuffled_cards.span(), seed);

            world.write_model(@deck);
        }

        fn post_blinds(ref self: ContractState, table_id: u32) {
            let mut world = self.world_default();
            let mut table: Table = world.read_model(table_id);
            let table_players: TablePlayers = world.read_model(table_id);

            // Validate state
            assert(table.status == GameStatus::InProgress.into(), 'Game not in progress');
            assert(table.current_round == GameRound::PreFlop.into(), 'Not preflop');
            assert(table_players.player_count >= 2, 'Need at least 2 players');

            let small_blind_pos = self.get_small_blind_position(@table);
            let big_blind_pos = self.get_big_blind_position(@table);

            let sb_player_addr = *table_players.players.at(small_blind_pos.into());
            let bb_player_addr = *table_players.players.at(big_blind_pos.into());

            let mut sb_player: Player = world.read_model((sb_player_addr, table_id));
            let mut bb_player: Player = world.read_model((bb_player_addr, table_id));

            // Post blinds
            assert(sb_player.post_blind(table.small_blind), 'Failed to post SB');
            assert(bb_player.post_blind(table.big_blind), 'Failed to post BB');

            // Update table pot and betting state
            table.post_blinds();

            if table.current_players == 2 {
                // Heads-up: dealer acts first preflop
                table.current_player_position = table.dealer_position;
            } else {
                // Multi-way: first player after big blind acts first
                table.current_player_position = (table.dealer_position + 3) % table.current_players;
            }

            // Write updates
            world.write_model(@table);
            world.write_model(@sb_player);
            world.write_model(@bb_player);

            // Emit event
            world
                .emit_event(
                    @BlindsPosted {
                        table_id,
                        small_blind_player: sb_player_addr,
                        big_blind_player: bb_player_addr,
                        small_blind_amount: table.small_blind,
                        big_blind_amount: table.big_blind,
                    },
                );
        }

        fn deal_hole_cards(ref self: ContractState, table_id: u32) {
            let mut world = self.world_default();
            let table: Table = world.read_model(table_id);
            let table_players: TablePlayers = world.read_model(table_id);
            let mut deck: GameDeck = world.read_model((table_id, table.game_number));

            // Validate state
            assert(table.status == GameStatus::InProgress.into(), 'Game not in progress');
            assert(table.current_round == GameRound::PreFlop.into(), 'Not preflop');

            // Deal 2 cards to each player
            let mut player_idx = 0;
            while player_idx < table_players.player_count {
                let player_addr = *table_players.players.at(player_idx.into());
                let mut player: Player = world.read_model((player_addr, table_id));

                // Deal 2 hole cards
                let card1 = deck.deal_next_card();
                let card2 = deck.deal_next_card();

                player.deal_hole_cards(card1, card2);
                world.write_model(@player);

                player_idx += 1;
            };

            // Save updated deck
            world.write_model(@deck);

            // Emit event
            world
                .emit_event(
                    @HoleCardsDealt {
                        table_id,
                        game_number: table.game_number,
                        player_count: table_players.player_count,
                    },
                );
        }

        fn deal_flop(ref self: ContractState, table_id: u32) {
            let mut world = self.world_default();
            let table: Table = world.read_model(table_id);
            let mut deck: GameDeck = world.read_model((table_id, table.game_number));
            let mut community: CommunityCards = world.read_model((table_id, table.game_number));

            // Validate state
            assert(table.status == GameStatus::InProgress.into(), 'Game not in progress');
            assert(table.current_round == GameRound::Flop.into(), 'Not flop round');

            // Burn one card, then deal 3 community cards
            deck.deal_next_card(); // Burn card

            let flop1 = deck.deal_next_card();
            let flop2 = deck.deal_next_card();
            let flop3 = deck.deal_next_card();

            community.deal_flop(flop1, flop2, flop3);

            // Write updates
            world.write_model(@deck);
            world.write_model(@community);

            // Emit event
            world
                .emit_event(
                    @CommunityCardsDealt {
                        table_id,
                        game_number: table.game_number,
                        round: GameRound::Flop.into(),
                        cards_dealt: 3,
                    },
                );
        }

        fn deal_turn(ref self: ContractState, table_id: u32) {
            let mut world = self.world_default();
            let table: Table = world.read_model(table_id);
            let mut deck: GameDeck = world.read_model((table_id, table.game_number));
            let mut community: CommunityCards = world.read_model((table_id, table.game_number));

            // Validate state
            assert(table.status == GameStatus::InProgress.into(), 'Game not in progress');
            assert(table.current_round == GameRound::Turn.into(), 'Not turn round');

            // Burn one card, then deal turn
            deck.deal_next_card(); // Burn card
            let turn_card = deck.deal_next_card();

            community.deal_turn(turn_card);

            // Write updates
            world.write_model(@deck);
            world.write_model(@community);

            // Emit event
            world
                .emit_event(
                    @CommunityCardsDealt {
                        table_id,
                        game_number: table.game_number,
                        round: GameRound::Turn.into(),
                        cards_dealt: 4,
                    },
                );
        }

        fn deal_river(ref self: ContractState, table_id: u32) {
            let mut world = self.world_default();
            let table: Table = world.read_model(table_id);
            let mut deck: GameDeck = world.read_model((table_id, table.game_number));
            let mut community: CommunityCards = world.read_model((table_id, table.game_number));

            // Validate state
            assert(table.status == GameStatus::InProgress.into(), 'Game not in progress');
            assert(table.current_round == GameRound::River.into(), 'Not river round');

            // Burn one card, then deal river
            deck.deal_next_card(); // Burn card
            let river_card = deck.deal_next_card();

            community.deal_river(river_card);

            // Write updates
            world.write_model(@deck);
            world.write_model(@community);

            // Emit event
            world
                .emit_event(
                    @CommunityCardsDealt {
                        table_id,
                        game_number: table.game_number,
                        round: GameRound::River.into(),
                        cards_dealt: 5,
                    },
                );
        }

        fn player_action(
            ref self: ContractState, table_id: u32, action: PlayerAction, amount: u128,
        ) {
            let mut world = self.world_default();
            let caller = get_caller_address();
            let mut table: Table = world.read_model(table_id);
            let table_players: TablePlayers = world.read_model(table_id);
            let mut player: Player = world.read_model((caller, table_id));

            // Validate it's the player's turn
            let current_player_addr = self.get_current_player_address(@table, @table_players);
            assert(caller == current_player_addr, 'Not your turn');

            // Validate player can perform this action
            assert(
                player.can_perform_action(action, table.current_bet, table.get_min_raise()),
                'Invalid action',
            );

            // Process the action
            match action {
                PlayerAction::Fold => { player.fold(); },
                PlayerAction::Check => { player.check(); },
                PlayerAction::Call => {
                    let call_amount = player.get_call_amount(table.current_bet);
                    assert(player.call(table.current_bet), 'Call failed');
                    table.add_to_pot(call_amount);
                },
                PlayerAction::Raise => {
                    assert(amount >= table.get_min_raise(), 'Raise too small');
                    let raise_amount = amount;
                    let total_bet = table.current_bet + raise_amount;
                    let additional_amount = total_bet - player.current_bet;

                    assert(player.raise(raise_amount, table.current_bet), 'Raise failed');
                    table.update_current_bet(total_bet, raise_amount);
                    table.add_to_pot(additional_amount);
                },
                PlayerAction::AllIn => {
                    let all_in_amount = player.go_all_in();
                    table.add_to_pot(all_in_amount);

                    // If all-in is larger than current bet, update it
                    if player.current_bet > table.current_bet {
                        let raise_amount = player.current_bet - table.current_bet;
                        table.update_current_bet(player.current_bet, raise_amount);
                    }
                },
            }

            // Advance to next player
            table.advance_to_next_player();

            // Write updates
            world.write_model(@table);
            world.write_model(@player);

            // Emit event
            world
                .emit_event(
                    @PlayerActed {
                        table_id,
                        player: caller,
                        action: action.into(),
                        amount,
                        pot_total: table.pot_total,
                    },
                );
        }

        fn check_round_complete(self: @ContractState, table_id: u32) -> bool {
            let world = self.world_default();
            let table: Table = world.read_model(table_id);

            let active_players = self.count_active_players(table_id);
            table.is_betting_round_complete(active_players)
        }

        fn advance_betting_round(ref self: ContractState, table_id: u32) {
            let mut world = self.world_default();
            let mut table: Table = world.read_model(table_id);
            let table_players: TablePlayers = world.read_model(table_id);

            // Reset all players for new round
            let mut i = 0;
            while i < table_players.player_count {
                let player_addr = *table_players.players.at(i.into());
                let mut player: Player = world.read_model((player_addr, table_id));

                if player.is_active {
                    player.reset_for_new_round();
                    world.write_model(@player);
                }
                i += 1;
            };

            // Advance the table round
            let round_advanced = table.advance_round();
            assert(round_advanced, 'Cannot advance round');

            if table.current_round != GameRound::PreFlop.into() {
                // Postflop: first active player after dealer acts first
                table.current_player_position = (table.dealer_position + 1) % table.current_players;
            }

            world.write_model(@table);

            // Emit event
            world
                .emit_event(
                    @BettingRoundComplete {
                        table_id, round: table.current_round, pot_total: table.pot_total,
                    },
                );
        }

        fn evaluate_hands(ref self: ContractState, table_id: u32) {
            let mut world = self.world_default();
            let table: Table = world.read_model(table_id);

            // This would implement hand evaluation logic
            assert(table.status == GameStatus::Showdown.into(), 'Not in showdown');
            // TODO: Implement proper hand evaluation
        }

        fn distribute_pot(ref self: ContractState, table_id: u32) {
            let mut world = self.world_default();
            let mut table: Table = world.read_model(table_id);

            // TODO: Implement proper pot distribution based on hand evaluation

            let winners = self.get_active_players(table_id);
            if winners.len() > 0 {
                let winner_addr = *winners.at(0);
                let mut winner: Player = world.read_model((winner_addr, table_id));

                winner.stack += table.pot_total;
                world.write_model(@winner);

                world
                    .emit_event(
                        @PotDistributed {
                            table_id,
                            winner: winner_addr,
                            amount: table.pot_total,
                            hand_rank: 0 // TODO: actual hand rank
                        },
                    );
            }

            // End the game
            table.end_game();
            world.write_model(@table);
        }

        // View functions
        fn get_current_bet(self: @ContractState, table_id: u32) -> u128 {
            let world = self.world_default();
            let table: Table = world.read_model(table_id);
            table.current_bet
        }

        fn get_active_players(self: @ContractState, table_id: u32) -> Array<ContractAddress> {
            let world = self.world_default();
            let table_players: TablePlayers = world.read_model(table_id);
            let mut active_players = array![];

            let mut i = 0;
            while i < table_players.player_count {
                let player_addr = *table_players.players.at(i.into());
                let player: Player = world.read_model((player_addr, table_id));

                if player.is_active {
                    active_players.append(player_addr);
                }
                i += 1;
            };

            active_players
        }

        fn get_player_to_act(self: @ContractState, table_id: u32) -> ContractAddress {
            let world = self.world_default();
            let table: Table = world.read_model(table_id);
            let table_players: TablePlayers = world.read_model(table_id);

            self.get_current_player_address(@table, @table_players)
        }

        fn can_player_act(self: @ContractState, table_id: u32, player: ContractAddress) -> bool {
            let world = self.world_default();
            let table: Table = world.read_model(table_id);
            let table_players: TablePlayers = world.read_model(table_id);
            let player_data: Player = world.read_model((player, table_id));

            let current_player = self.get_current_player_address(@table, @table_players);
            current_player == player && player_data.is_active && !player_data.has_acted
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn world_default(self: @ContractState) -> dojo::world::WorldStorage {
            self.world(@"pojo")
        }

        // TODO
        fn create_shuffled_deck(self: @ContractState, seed: felt252) -> Array<u8> {
            let mut shuffled = array![];

            let mut deck = DeckTrait::new(seed, DECK_SIZE.into());

            for _ in 0..DECK_SIZE {
                let card = deck.draw();
                shuffled.append(card.into());
            };

            shuffled
        }

        fn get_small_blind_position(self: @ContractState, table: @Table) -> u8 {
            if *table.current_players == 2 {
                *table.dealer_position // Heads-up: dealer is small blind
            } else {
                (*table.dealer_position + 1) % *table.current_players
            }
        }

        fn get_big_blind_position(self: @ContractState, table: @Table) -> u8 {
            if *table.current_players == 2 {
                (*table.dealer_position + 1) % *table.current_players // Heads-up: non-dealer is BB
            } else {
                (*table.dealer_position + 2) % *table.current_players
            }
        }

        fn get_current_player_address(
            self: @ContractState, table: @Table, table_players: @TablePlayers,
        ) -> ContractAddress {
            *(*table_players.players).at((*table.current_player_position).into())
        }

        fn count_active_players(self: @ContractState, table_id: u32) -> u8 {
            let world = self.world_default();
            let table_players: TablePlayers = world.read_model(table_id);
            let mut active_count = 0;

            let mut i = 0;
            while i < table_players.player_count {
                let player_addr = *table_players.players.at(i.into());
                let player: Player = world.read_model((player_addr, table_id));

                if player.is_active {
                    active_count += 1;
                }
                i += 1;
            };

            active_count
        }
    }
}
