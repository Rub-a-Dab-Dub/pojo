#[cfg(test)]
mod game_system_tests {
    use dojo_cairo_test::WorldStorageTestTrait;
    use dojo::model::{ModelStorage, ModelStorageTest};
    use dojo::world::{WorldStorage, WorldStorageTrait};
    use dojo_cairo_test::{
        spawn_test_world, NamespaceDef, TestResource, ContractDefTrait, ContractDef,
    };
    use starknet::{contract_address_const, ContractAddress, testing};

    use pojo::constants::GAME_ID;
    use pojo::systems::table::{
        table_systems, ITableSystems, ITableSystemsDispatcher, ITableSystemsDispatcherTrait,
    };
    use pojo::systems::game::{
        game_systems, IGameSystems, IGameSystemsDispatcher, IGameSystemsDispatcherTrait,
    };
    use pojo::models::table::{
        Table, TableCount, TablePlayers, GameDeck, CommunityCards, GameStatus, GameRound, m_Table,
        m_TableCount, m_TablePlayers, m_GameDeck, m_CommunityCards, CommunityCardsTrait,
    };
    use pojo::models::player::{Player, PlayerAction, m_Player, PlayerTrait};

    fn namespace_def() -> NamespaceDef {
        let ndef = NamespaceDef {
            namespace: "pojo",
            resources: [
                // Models
                TestResource::Model(m_Table::TEST_CLASS_HASH),
                TestResource::Model(m_TableCount::TEST_CLASS_HASH),
                TestResource::Model(m_TablePlayers::TEST_CLASS_HASH),
                TestResource::Model(m_GameDeck::TEST_CLASS_HASH),
                TestResource::Model(m_CommunityCards::TEST_CLASS_HASH),
                TestResource::Model(m_Player::TEST_CLASS_HASH),
                // Table system events
                TestResource::Event(table_systems::e_GameStarted::TEST_CLASS_HASH),
                TestResource::Event(table_systems::e_PlayerJoinedTable::TEST_CLASS_HASH),
                TestResource::Event(table_systems::e_PlayerLeaveTable::TEST_CLASS_HASH),
                TestResource::Event(table_systems::e_TableCreated::TEST_CLASS_HASH),
                TestResource::Event(table_systems::e_GameReadyToStart::TEST_CLASS_HASH),
                // Game system events
                TestResource::Event(game_systems::e_HoleCardsDealt::TEST_CLASS_HASH),
                TestResource::Event(game_systems::e_CommunityCardsDealt::TEST_CLASS_HASH),
                TestResource::Event(game_systems::e_PlayerActed::TEST_CLASS_HASH),
                TestResource::Event(game_systems::e_BettingRoundComplete::TEST_CLASS_HASH),
                TestResource::Event(game_systems::e_PotDistributed::TEST_CLASS_HASH),
                TestResource::Event(game_systems::e_BlindsPosted::TEST_CLASS_HASH),
                // Contracts
                TestResource::Contract(table_systems::TEST_CLASS_HASH),
                TestResource::Contract(game_systems::TEST_CLASS_HASH),
            ]
                .span(),
        };

        ndef
    }

    fn contract_defs() -> Span<ContractDef> {
        [
            ContractDefTrait::new(@"pojo", @"table_systems")
                .with_writer_of([dojo::utils::bytearray_hash(@"pojo")].span()),
            ContractDefTrait::new(@"pojo", @"game_systems")
                .with_writer_of([dojo::utils::bytearray_hash(@"pojo")].span()),
        ]
            .span()
    }

    // Test addresses
    fn alice() -> ContractAddress {
        contract_address_const::<0x1234>()
    }
    fn bob() -> ContractAddress {
        contract_address_const::<0x5678>()
    }
    fn charlie() -> ContractAddress {
        contract_address_const::<0x9abc>()
    }
    fn zero() -> ContractAddress {
        contract_address_const::<0x0>()
    }

    fn setup_test_contracts() -> (ITableSystemsDispatcher, IGameSystemsDispatcher, WorldStorage) {
        let ndef = namespace_def();
        let mut world: WorldStorage = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (table_contract_address, _) = world.dns(@"table_systems").unwrap();
        let (game_contract_address, _) = world.dns(@"game_systems").unwrap();

        let table_system = ITableSystemsDispatcher { contract_address: table_contract_address };
        let game_system = IGameSystemsDispatcher { contract_address: game_contract_address };

        (table_system, game_system, world)
    }

    fn setup_game_ready_table() -> (
        ITableSystemsDispatcher, IGameSystemsDispatcher, WorldStorage, u32,
    ) {
        let (mut table_system, game_system, mut world) = setup_test_contracts();

        // Initialize table count
        let table_count = TableCount { id: GAME_ID, count: 0 };
        world.write_model(@table_count);

        // Create table
        testing::set_account_contract_address(alice());
        testing::set_contract_address(alice());
        let table_id = table_system.create_table(10, 20, 400, 2000, 6);

        // Add players
        table_system.join_table(table_id, 1000);

        testing::set_account_contract_address(bob());
        testing::set_contract_address(bob());
        table_system.join_table(table_id, 1500);

        // Start game
        testing::set_account_contract_address(alice());
        testing::set_contract_address(alice());
        table_system.start_game(table_id);

        testing::set_account_contract_address(zero());
        testing::set_contract_address(zero());
        (table_system, game_system, world, table_id)
    }

    #[test]
    fn test_shuffle_deck() {
        let (_, mut game_system, mut world, table_id) = setup_game_ready_table();

        // Shuffle deck
        testing::set_account_contract_address(alice());
        testing::set_contract_address(alice());
        game_system.shuffle_deck(table_id, 12345);

        // Verify deck was created
        let table: Table = world.read_model(table_id);
        let deck: GameDeck = world.read_model((table_id, table.game_number));

        assert(deck.table_id == table_id, 'Wrong table ID in deck');
        assert(deck.game_number == table.game_number, 'Wrong game number');
        assert(deck.seed == 12345, 'Wrong seed');
        assert(deck.next_card_index == 0, 'Should start at index 0');
    }

    #[test]
    fn test_post_blinds() {
        let (_, mut game_system, mut world, table_id) = setup_game_ready_table();

        // Shuffle deck and initialize community cards
        game_system.shuffle_deck(table_id, 12345);

        let table: Table = world.read_model(table_id);
        let community = CommunityCardsTrait::new(table_id, table.game_number);
        world.write_model(@community);

        // Post blinds
        game_system.post_blinds(table_id);

        // Verify blinds were posted
        let updated_table: Table = world.read_model(table_id);
        assert(updated_table.pot_total == 30, 'Pot should be SB + BB = 30');
        assert(updated_table.current_bet == 20, 'Current bet should be BB');

        // Verify players posted blinds
        let alice_player: Player = world.read_model((alice(), table_id));
        let bob_player: Player = world.read_model((bob(), table_id));

        // Alice is position 0 (dealer in heads-up = SB)
        assert(alice_player.current_bet == 10, 'Alice should post SB');
        assert(alice_player.stack == 990, 'Alice stack should decrease');

        // Bob is position 1 (non-dealer in heads-up = BB)
        assert(bob_player.current_bet == 20, 'Bob should post BB');
        assert(bob_player.stack == 1480, 'Bob stack should decrease');
    }

    #[test]
    fn test_deal_hole_cards() {
        let (_, mut game_system, mut world, table_id) = setup_game_ready_table();

        // Setup game state
        game_system.shuffle_deck(table_id, 12345);

        let table: Table = world.read_model(table_id);
        let community = CommunityCardsTrait::new(table_id, table.game_number);
        world.write_model(@community);

        game_system.post_blinds(table_id);

        // Deal hole cards
        game_system.deal_hole_cards(table_id);

        // Verify players received cards
        let alice_player: Player = world.read_model((alice(), table_id));
        let bob_player: Player = world.read_model((bob(), table_id));

        assert!(alice_player.has_hole_cards(), "Alice should have hole cards");
        assert(bob_player.has_hole_cards(), 'Bob should have hole cards');
        assert(alice_player.hole_card1 != alice_player.hole_card2, 'Alice cards should differ');
        assert(bob_player.hole_card1 != bob_player.hole_card2, 'Bob cards should differ');

        // Verify deck advanced
        let deck: GameDeck = world.read_model((table_id, table.game_number));
        assert(deck.next_card_index == 4, 'Should have dealt 4 cards total');
    }

    #[test]
    fn test_player_actions() {
        let (_, mut game_system, mut world, table_id) = setup_game_ready_table();

        // Setup complete game state
        game_system.shuffle_deck(table_id, 12345);

        let table: Table = world.read_model(table_id);
        let community = CommunityCardsTrait::new(table_id, table.game_number);
        world.write_model(@community);

        game_system.post_blinds(table_id);
        game_system.deal_hole_cards(table_id);

        // In heads-up preflop, dealer (Alice) acts first
        let current_player = game_system.get_player_to_act(table_id);
        assert!(current_player == alice(), "Alice should act first in heads-up preflop");

        // Alice calls (completes the BB)
        testing::set_account_contract_address(alice());
        testing::set_contract_address(alice());
        game_system.player_action(table_id, PlayerAction::Call, 0);

        // Verify Alice's action
        let alice_after_call: Player = world.read_model((alice(), table_id));
        assert(alice_after_call.current_bet == 20, 'Alice should have called to 20');
        assert!(alice_after_call.stack == 980, "Alice stack should decrease by 10 more");
        assert(alice_after_call.has_acted, 'Alice should have acted');

        // Now it's Bob's turn (BB can check)
        let current_player_after = game_system.get_player_to_act(table_id);
        assert(current_player_after == bob(), 'Bob should act next');

        // Bob checks
        testing::set_account_contract_address(bob());
        testing::set_contract_address(bob());
        game_system.player_action(table_id, PlayerAction::Check, 0);

        // Verify Bob's action
        let bob_after_check: Player = world.read_model((bob(), table_id));
        assert(bob_after_check.has_acted, 'Bob should have acted');

        // Check if round is complete
        let round_complete = game_system.check_round_complete(table_id);
        assert!(round_complete, "Betting round should be complete");
    }

    #[test]
    fn test_raise_action() {
        let (_, mut game_system, mut world, table_id) = setup_game_ready_table();

        // Setup game
        game_system.shuffle_deck(table_id, 12345);

        let table: Table = world.read_model(table_id);
        let community = CommunityCardsTrait::new(table_id, table.game_number);
        world.write_model(@community);

        game_system.post_blinds(table_id);
        game_system.deal_hole_cards(table_id);

        // Alice raises instead of calling
        testing::set_account_contract_address(alice());
        testing::set_contract_address(alice());
        game_system.player_action(table_id, PlayerAction::Raise, 30); // Raise to 50 total

        // Verify raise was processed
        let table_after_raise: Table = world.read_model(table_id);
        assert(table_after_raise.current_bet == 50, 'Current bet should be 50');
        assert(table_after_raise.last_raise_amount == 30, 'Raise amount should be 30');

        let alice_after_raise: Player = world.read_model((alice(), table_id));
        assert(alice_after_raise.current_bet == 50, 'Alice should have bet 50 total');
        assert!(alice_after_raise.stack == 950, "Alice stack should decrease by 50");

        // Bob can now call, raise, or fold
        testing::set_account_contract_address(bob());
        testing::set_contract_address(bob());

        // Bob calls the raise
        game_system.player_action(table_id, PlayerAction::Call, 0);

        let bob_after_call: Player = world.read_model((bob(), table_id));
        assert(bob_after_call.current_bet == 50, 'Bob should match the 50');
        assert(bob_after_call.stack == 1450, 'Bob should pay 30 more to call');
    }

    #[test]
    fn test_fold_action() {
        let (_, mut game_system, mut world, table_id) = setup_game_ready_table();

        // Setup game
        game_system.shuffle_deck(table_id, 12345);

        let table: Table = world.read_model(table_id);
        let community = CommunityCardsTrait::new(table_id, table.game_number);
        world.write_model(@community);

        game_system.post_blinds(table_id);
        game_system.deal_hole_cards(table_id);

        // Alice folds
        testing::set_account_contract_address(alice());
        testing::set_contract_address(alice());
        game_system.player_action(table_id, PlayerAction::Fold, 0);

        // Verify fold
        let alice_after_fold: Player = world.read_model((alice(), table_id));
        assert(!alice_after_fold.is_active, 'Alice should be inactive');
        assert(alice_after_fold.has_acted, 'Alice should have acted');

        let active_players = game_system.get_active_players(table_id);
        assert(active_players.len() == 1, 'Should have 1 active player');
        assert(*active_players.at(0) == bob(), 'Bob should be the active player');
    }

    #[test]
    fn test_all_in_action() {
        let (_, mut game_system, mut world, table_id) = setup_game_ready_table();

        // Setup game
        game_system.shuffle_deck(table_id, 12345);

        let table: Table = world.read_model(table_id);
        let community = CommunityCardsTrait::new(table_id, table.game_number);
        world.write_model(@community);

        game_system.post_blinds(table_id);
        game_system.deal_hole_cards(table_id);

        // Alice goes all-in
        testing::set_account_contract_address(alice());
        testing::set_contract_address(alice());
        game_system.player_action(table_id, PlayerAction::AllIn, 0);

        // Verify all-in
        let alice_after_allin: Player = world.read_model((alice(), table_id));
        assert(alice_after_allin.stack == 0, 'Alice should have no stack left');
        assert!(alice_after_allin.current_bet == 1000, "Alice should bet her remaining stack");
        assert(alice_after_allin.is_all_in(), 'Alice should be all-in');

        let table_after_allin: Table = world.read_model(table_id);
        assert!(table_after_allin.current_bet == 1000, "Table bet should be Alice all-in amount");
    }

    #[test]
    fn test_advance_betting_round() {
        let (_, mut game_system, mut world, table_id) = setup_game_ready_table();

        // Setup and complete preflop betting
        game_system.shuffle_deck(table_id, 12345);

        let table: Table = world.read_model(table_id);
        let community = CommunityCardsTrait::new(table_id, table.game_number);
        world.write_model(@community);

        game_system.post_blinds(table_id);
        game_system.deal_hole_cards(table_id);

        // Complete preflop betting
        testing::set_account_contract_address(alice());
        testing::set_contract_address(alice());
        game_system.player_action(table_id, PlayerAction::Call, 0);

        testing::set_account_contract_address(bob());
        testing::set_contract_address(bob());
        game_system.player_action(table_id, PlayerAction::Check, 0);

        // Advance to flop
        game_system.advance_betting_round(table_id);

        // Verify round advancement
        let table_after_advance: Table = world.read_model(table_id);
        assert(table_after_advance.current_round == GameRound::Flop.into(), 'Should be flop round');
        assert(table_after_advance.current_bet == 0, 'Current bet should reset');
        assert(table_after_advance.players_acted_this_round == 0, 'Actions should reset');

        // Verify players reset for new round
        let alice_after_advance: Player = world.read_model((alice(), table_id));
        let bob_after_advance: Player = world.read_model((bob(), table_id));

        assert(alice_after_advance.current_bet == 0, 'Alice current bet should reset');
        assert(!alice_after_advance.has_acted, 'Alice has_acted should reset');
        assert(bob_after_advance.current_bet == 0, 'Bob current bet should reset');
        assert(!bob_after_advance.has_acted, 'Bob has_acted should reset');
    }

    #[test]
    fn test_deal_flop() {
        let (_, mut game_system, mut world, table_id) = setup_game_ready_table();

        // Setup and advance to flop
        game_system.shuffle_deck(table_id, 12345);

        let table: Table = world.read_model(table_id);
        let community = CommunityCardsTrait::new(table_id, table.game_number);
        world.write_model(@community);

        game_system.post_blinds(table_id);
        game_system.deal_hole_cards(table_id);

        // Complete preflop
        testing::set_account_contract_address(alice());
        testing::set_contract_address(alice());
        game_system.player_action(table_id, PlayerAction::Call, 0);

        testing::set_account_contract_address(bob());
        testing::set_contract_address(bob());
        game_system.player_action(table_id, PlayerAction::Check, 0);

        game_system.advance_betting_round(table_id);

        // Deal flop
        game_system.deal_flop(table_id);

        // Verify flop was dealt
        let community_after: CommunityCards = world.read_model((table_id, table.game_number));
        assert(community_after.has_flop(), 'Should have flop');
        assert(community_after.cards_dealt == 3, 'Should have 3 cards dealt');

        let dealt_cards = community_after.get_dealt_cards();
        assert(dealt_cards.len() == 3, 'Should have 3 community cards');

        // Verify deck advanced (4 hole cards + 1 burn + 3 flop = 8)
        let deck: GameDeck = world.read_model((table_id, table.game_number));
        assert(deck.next_card_index == 8, 'Deck should be at index 8');
    }

    #[test]
    fn test_deal_turn() {
        let (_, mut game_system, mut world, table_id) = setup_game_ready_table();

        // Setup through flop
        game_system.shuffle_deck(table_id, 12345);

        let table: Table = world.read_model(table_id);
        let community = CommunityCardsTrait::new(table_id, table.game_number);
        world.write_model(@community);

        game_system.post_blinds(table_id);
        game_system.deal_hole_cards(table_id);

        // Complete preflop
        testing::set_account_contract_address(alice());
        testing::set_contract_address(alice());
        game_system.player_action(table_id, PlayerAction::Call, 0);

        testing::set_account_contract_address(bob());
        testing::set_contract_address(bob());
        game_system.player_action(table_id, PlayerAction::Check, 0);

        game_system.advance_betting_round(table_id);
        game_system.deal_flop(table_id);

        // Complete flop betting
        testing::set_account_contract_address(bob());
        testing::set_contract_address(bob());
        game_system.player_action(table_id, PlayerAction::Check, 0);

        testing::set_account_contract_address(alice());
        testing::set_contract_address(alice());
        game_system.player_action(table_id, PlayerAction::Check, 0);

        game_system.advance_betting_round(table_id);

        // Deal turn
        game_system.deal_turn(table_id);

        // Verify turn was dealt
        let community_after: CommunityCards = world.read_model((table_id, table.game_number));
        assert(community_after.has_turn(), 'Should have turn');
        assert(community_after.cards_dealt == 4, 'Should have 4 cards dealt');

        let dealt_cards = community_after.get_dealt_cards();
        assert(dealt_cards.len() == 4, 'Should have 4 community cards');
    }

    #[test]
    fn test_deal_river() {
        let (_, mut game_system, mut world, table_id) = setup_game_ready_table();

        // Setup through turn (abbreviated for brevity)
        game_system.shuffle_deck(table_id, 12345);

        let table: Table = world.read_model(table_id);
        let community = CommunityCardsTrait::new(table_id, table.game_number);
        world.write_model(@community);

        game_system.post_blinds(table_id);
        game_system.deal_hole_cards(table_id);

        // Fast-forward through betting rounds to river
        // (In real test, would go through each round properly)

        // Manually set table to river round for this test
        let mut table_manual: Table = world.read_model(table_id);
        table_manual.current_round = GameRound::River.into();
        world.write_model(@table_manual);

        // Manually deal flop and turn first
        let mut community_manual = community;
        community_manual.deal_flop(5, 18, 31);
        community_manual.deal_turn(44);
        world.write_model(@community_manual);

        // Deal river
        game_system.deal_river(table_id);

        // Verify river was dealt
        let community_final: CommunityCards = world.read_model((table_id, table.game_number));
        assert(community_final.has_river(), 'Should have river');
        assert(community_final.cards_dealt == 5, 'Should have 5 cards dealt');

        let dealt_cards = community_final.get_dealt_cards();
        assert(dealt_cards.len() == 5, 'Should have 5 community cards');
    }

    #[test]
    #[should_panic(expected: ('Not your turn', 'ENTRYPOINT_FAILED'))]
    fn test_player_action_wrong_turn() {
        let (_, mut game_system, mut world, table_id) = setup_game_ready_table();

        // Setup game
        game_system.shuffle_deck(table_id, 12345);

        let table: Table = world.read_model(table_id);
        let community = CommunityCardsTrait::new(table_id, table.game_number);
        world.write_model(@community);

        game_system.post_blinds(table_id);
        game_system.deal_hole_cards(table_id);

        // Bob tries to act when it's Alice's turn
        testing::set_account_contract_address(bob());
        testing::set_contract_address(bob());
        game_system.player_action(table_id, PlayerAction::Check, 0);
    }

    #[test]
    #[should_panic(expected: ('Invalid action', 'ENTRYPOINT_FAILED'))]
    fn test_invalid_check() {
        let (_, mut game_system, mut world, table_id) = setup_game_ready_table();

        // Setup game
        game_system.shuffle_deck(table_id, 12345);

        let table: Table = world.read_model(table_id);
        let community = CommunityCardsTrait::new(table_id, table.game_number);
        world.write_model(@community);

        game_system.post_blinds(table_id);
        game_system.deal_hole_cards(table_id);

        // Alice tries to check when she needs to call or raise (there's a bet to call)
        testing::set_account_contract_address(alice());
        testing::set_contract_address(alice());
        game_system.player_action(table_id, PlayerAction::Check, 0);
    }

    #[test]
    #[should_panic(expected: ('Raise too small', 'ENTRYPOINT_FAILED'))]
    fn test_raise_too_small() {
        let (_, mut game_system, mut world, table_id) = setup_game_ready_table();

        // Setup game
        game_system.shuffle_deck(table_id, 12345);

        let table: Table = world.read_model(table_id);
        let community = CommunityCardsTrait::new(table_id, table.game_number);
        world.write_model(@community);

        game_system.post_blinds(table_id);
        game_system.deal_hole_cards(table_id);

        // Alice tries to raise by less than the minimum
        testing::set_account_contract_address(alice());
        testing::set_contract_address(alice());
        game_system.player_action(table_id, PlayerAction::Raise, 5); // Min raise should be 20 (BB)
    }

    #[test]
    fn test_view_functions() {
        let (_, game_system, mut world, table_id) = setup_game_ready_table();

        // Setup game
        game_system.shuffle_deck(table_id, 12345);

        let table: Table = world.read_model(table_id);
        let community = CommunityCardsTrait::new(table_id, table.game_number);
        world.write_model(@community);

        game_system.post_blinds(table_id);

        // Test view functions
        let current_bet = game_system.get_current_bet(table_id);
        assert(current_bet == 20, 'Current bet should be BB amount');

        let active_players = game_system.get_active_players(table_id);
        assert(active_players.len() == 2, 'Should have 2 active players');

        let player_to_act = game_system.get_player_to_act(table_id);
        assert(player_to_act == alice(), 'Alice should be first to act');

        let alice_can_act = game_system.can_player_act(table_id, alice());
        let bob_can_act = game_system.can_player_act(table_id, bob());
        assert(alice_can_act, 'Alice should be able to act');
        assert!(!bob_can_act, "Bob should not be able to act yet");
    }

    #[test]
    fn test_full_hand_simulation() {
        let (_, mut game_system, mut world, table_id) = setup_game_ready_table();

        // Complete hand simulation
        game_system.shuffle_deck(table_id, 12345);

        let table: Table = world.read_model(table_id);
        let community = CommunityCardsTrait::new(table_id, table.game_number);
        world.write_model(@community);

        // Preflop
        game_system.post_blinds(table_id);
        game_system.deal_hole_cards(table_id);

        testing::set_account_contract_address(alice());
        testing::set_contract_address(alice());
        game_system.player_action(table_id, PlayerAction::Call, 0);

        testing::set_account_contract_address(bob());
        testing::set_contract_address(bob());
        game_system.player_action(table_id, PlayerAction::Check, 0);

        assert(game_system.check_round_complete(table_id), 'Preflop should be complete');

        // Flop
        game_system.advance_betting_round(table_id);
        game_system.deal_flop(table_id);

        testing::set_account_contract_address(bob());
        testing::set_contract_address(bob());
        game_system.player_action(table_id, PlayerAction::Check, 0);

        testing::set_account_contract_address(alice());
        testing::set_contract_address(alice());
        game_system.player_action(table_id, PlayerAction::Check, 0);

        // Turn
        game_system.advance_betting_round(table_id);
        game_system.deal_turn(table_id);

        testing::set_account_contract_address(bob());
        testing::set_contract_address(bob());
        game_system.player_action(table_id, PlayerAction::Check, 0);

        testing::set_account_contract_address(alice());
        testing::set_contract_address(alice());
        game_system.player_action(table_id, PlayerAction::Check, 0);

        // River
        game_system.advance_betting_round(table_id);
        game_system.deal_river(table_id);

        testing::set_account_contract_address(bob());
        testing::set_contract_address(bob());
        game_system.player_action(table_id, PlayerAction::Check, 0);

        testing::set_account_contract_address(alice());
        testing::set_contract_address(alice());
        game_system.player_action(table_id, PlayerAction::Check, 0);

        // Should advance to showdown
        game_system.advance_betting_round(table_id);

        let final_table: Table = world.read_model(table_id);
        assert(final_table.status == GameStatus::Showdown.into(), 'Should be in showdown');
        assert(final_table.current_round == GameRound::Showdown.into(), 'Should be showdown round');

        // Verify all community cards were dealt
        let final_community: CommunityCards = world.read_model((table_id, final_table.game_number));
        assert(final_community.has_river(), 'Should have all community cards');
        assert(final_community.cards_dealt == 5, 'Should have 5 community cards');
    }

    #[test]
    fn test_heads_up_action_order() {
        let (_, mut game_system, mut world, table_id) = setup_game_ready_table();

        // Setup game
        game_system.shuffle_deck(table_id, 12345);

        let table: Table = world.read_model(table_id);
        let community = CommunityCardsTrait::new(table_id, table.game_number);
        world.write_model(@community);

        game_system.post_blinds(table_id);
        game_system.deal_hole_cards(table_id);

        // Preflop: Dealer (Alice) acts first in heads-up
        let preflop_first = game_system.get_player_to_act(table_id);
        assert!(preflop_first == alice(), "Dealer acts first preflop in heads-up");

        // Complete preflop
        testing::set_account_contract_address(alice());
        testing::set_contract_address(alice());
        game_system.player_action(table_id, PlayerAction::Call, 0);

        testing::set_account_contract_address(bob());
        testing::set_contract_address(bob());
        game_system.player_action(table_id, PlayerAction::Check, 0);

        // Advance to flop
        game_system.advance_betting_round(table_id);

        // Postflop: Non-dealer (Bob) acts first in heads-up
        let postflop_first = game_system.get_player_to_act(table_id);
        assert!(postflop_first == bob(), "Non-dealer acts first postflop in heads-up");
    }

    #[test]
    fn test_pot_calculation() {
        let (_, mut game_system, mut world, table_id) = setup_game_ready_table();

        // Setup game
        game_system.shuffle_deck(table_id, 12345);

        let table: Table = world.read_model(table_id);
        let community = CommunityCardsTrait::new(table_id, table.game_number);
        world.write_model(@community);

        game_system.post_blinds(table_id);

        // Initial pot should be blinds
        let initial_pot = game_system.get_current_bet(table_id);
        let table_after_blinds: Table = world.read_model(table_id);
        assert(table_after_blinds.pot_total == 30, 'Initial pot should be 30');

        game_system.deal_hole_cards(table_id);

        // Alice raises
        testing::set_account_contract_address(alice());
        testing::set_contract_address(alice());
        game_system.player_action(table_id, PlayerAction::Raise, 30); // Raise to 50

        let table_after_raise: Table = world.read_model(table_id);
        assert!(
            table_after_raise.pot_total == 70, "Pot should be 70 after Alice raises",
        ); // 30 + 40 more from Alice

        // Bob calls
        testing::set_account_contract_address(bob());
        testing::set_contract_address(bob());
        game_system.player_action(table_id, PlayerAction::Call, 0);

        let table_after_call: Table = world.read_model(table_id);
        assert!(
            table_after_call.pot_total == 100, "Pot should be 100 after Bob calls",
        ); // 70 + 30 more from Bob
    }
}
