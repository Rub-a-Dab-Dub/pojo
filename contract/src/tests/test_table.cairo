#[cfg(test)]
mod table_system_tests {
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
    use pojo::models::table::{
        TableTrait, m_TableCount, TableCountImpl, TableCountTrait, m_TablePlayers, m_Table,
        TablePlayersTrait, GameStatus, TableCount, TablePlayers, m_GameDeck, m_CommunityCards,
        Table,
    };
    use pojo::models::player::{PlayerTrait, Player, m_Player};


    fn namespace_def() -> NamespaceDef {
        let ndef = NamespaceDef {
            namespace: "pojo",
            resources: [
                TestResource::Model(m_Table::TEST_CLASS_HASH),
                TestResource::Model(m_TableCount::TEST_CLASS_HASH),
                TestResource::Model(m_TablePlayers::TEST_CLASS_HASH),
                TestResource::Model(m_GameDeck::TEST_CLASS_HASH),
                TestResource::Model(m_CommunityCards::TEST_CLASS_HASH),
                TestResource::Model(m_Player::TEST_CLASS_HASH),
                TestResource::Event(table_systems::e_GameStarted::TEST_CLASS_HASH),
                TestResource::Event(table_systems::e_PlayerJoinedTable::TEST_CLASS_HASH),
                TestResource::Event(table_systems::e_PlayerLeaveTable::TEST_CLASS_HASH),
                TestResource::Event(table_systems::e_TableCreated::TEST_CLASS_HASH),
                TestResource::Event(table_systems::e_GameReadyToStart::TEST_CLASS_HASH),
                TestResource::Contract(table_systems::TEST_CLASS_HASH),
            ]
                .span(),
        };

        ndef
    }

    fn contract_defs() -> Span<ContractDef> {
        [
            ContractDefTrait::new(@"pojo", @"table_systems")
                .with_writer_of([dojo::utils::bytearray_hash(@"pojo")].span())
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
    fn dave() -> ContractAddress {
        contract_address_const::<0xdef0>()
    }
    fn eve() -> ContractAddress {
        contract_address_const::<0x1111>()
    }
    fn zero() -> ContractAddress {
        contract_address_const::<0x0>()
    }

    fn setup_test_contract() -> (ITableSystemsDispatcher, WorldStorage) {
        let ndef = namespace_def();
        let mut world: WorldStorage = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"table_systems").unwrap();
        let mut table_system = ITableSystemsDispatcher { contract_address };

        (table_system, world)
    }

    #[test]
    fn test_create_table_success() {
        let (mut contract, mut world) = setup_test_contract();

        // Initialize table count
        let table_count = TableCount { id: GAME_ID, count: 0 };
        world.write_model(@table_count);

        testing::set_account_contract_address(alice());
        testing::set_contract_address(alice());
        let table_id = contract
            .create_table(
                small_blind: 10, big_blind: 20, min_buy_in: 400, max_buy_in: 2000, max_players: 6,
            );

        assert(table_id == 1, 'first table should be id 1');

        // Verify table was created
        let table: Table = world.read_model(table_id);
        assert(table.creator == alice(), 'wrong creator');

        assert(table.small_blind == 10, 'wrong small blind');
        assert(table.big_blind == 20, 'wrong big blind');
        assert(table.max_players == 6, 'wrong max players');

        // Verify table players was initialized
        let table_players: TablePlayers = world.read_model(table_id);
        assert(table_players.player_count == 0, 'should start with 0 players');

        // Verify table count was updated
        let updated_count: TableCount = world.read_model(GAME_ID);
        assert(updated_count.count == 1, 'count should be 1');
    }

    #[test]
    #[should_panic(expected: ('BB must be > SB', 'ENTRYPOINT_FAILED'))]
    fn test_create_table_invalid_blinds() {
        let (mut contract, mut world) = setup_test_contract();

        let table_count = TableCount { id: GAME_ID, count: 0 };
        world.write_model(@table_count);

        testing::set_account_contract_address(alice());
        testing::set_contract_address(alice());
        contract
            .create_table(
                small_blind: 20,
                big_blind: 10, // Invalid: BB <= SB
                min_buy_in: 400,
                max_buy_in: 2000,
                max_players: 6,
            );
    }

    #[test]
    #[should_panic(expected: ('Invalid max players', 'ENTRYPOINT_FAILED'))]
    fn test_create_table_invalid_players() {
        let (mut contract, mut world) = setup_test_contract();

        let table_count = TableCount { id: GAME_ID, count: 0 };
        world.write_model(@table_count);

        testing::set_account_contract_address(alice());
        testing::set_contract_address(alice());
        contract
            .create_table(
                small_blind: 10,
                big_blind: 20,
                min_buy_in: 400,
                max_buy_in: 2000,
                max_players: 1 // Invalid: < 2
            );
    }

    #[test]
    #[should_panic(expected: ('Min buy-in too small', 'ENTRYPOINT_FAILED'))]
    fn test_create_table_min_buyin_too_small() {
        let (mut contract, mut world) = setup_test_contract();

        let table_count = TableCount { id: GAME_ID, count: 0 };
        world.write_model(@table_count);

        testing::set_account_contract_address(alice());
        testing::set_contract_address(alice());
        contract
            .create_table(
                small_blind: 10,
                big_blind: 20,
                min_buy_in: 100, // Invalid: < 20 * BB
                max_buy_in: 2000,
                max_players: 6,
            );
    }

    #[test]
    fn test_join_table_success() {
        let (mut contract, mut world) = setup_test_contract();

        // Setup table
        let table_count = TableCount { id: GAME_ID, count: 0 };
        world.write_model(@table_count);

        testing::set_account_contract_address(alice());
        testing::set_contract_address(alice());
        let table_id = contract.create_table(10, 20, 400, 2000, 6);

        // Alice joins her own table
        contract.join_table(table_id, 1000);

        // Verify Alice was added
        let table: Table = world.read_model(table_id);
        assert(table.current_players == 1, 'should have 1 player');

        let table_players: TablePlayers = world.read_model(table_id);
        assert(table_players.player_count == 1, 'should have 1 in list');

        let alice_player: Player = world.read_model((alice(), table_id));
        assert(alice_player.stack == 1000, 'wrong stack');
        assert(alice_player.position == 0, 'wrong position');

        // Bob joins
        testing::set_account_contract_address(bob());
        testing::set_contract_address(bob());
        contract.join_table(table_id, 1500);

        // Verify Bob was added
        let updated_table: Table = world.read_model(table_id);
        assert(updated_table.current_players == 2, 'should have 2 players');

        let bob_player: Player = world.read_model((bob(), table_id));
        assert(bob_player.stack == 1500, 'wrong stack');
        assert(bob_player.position == 1, 'wrong position');
    }

    #[test]
    #[should_panic(expected: ('Invalid buy-in amount', 'ENTRYPOINT_FAILED'))]
    fn test_join_table_invalid_buyin() {
        let (mut contract, mut world) = setup_test_contract();

        let table_count = TableCount { id: GAME_ID, count: 0 };
        world.write_model(@table_count);

        testing::set_account_contract_address(alice());
        testing::set_contract_address(alice());
        let table_id = contract.create_table(10, 20, 400, 2000, 6);

        // Try to join with buy-in below minimum
        contract.join_table(table_id, 300);
    }

    #[test]
    #[should_panic(expected: ('Player already at table', 'ENTRYPOINT_FAILED'))]
    fn test_join_table_already_joined() {
        let (mut contract, mut world) = setup_test_contract();

        let table_count = TableCount { id: GAME_ID, count: 0 };
        world.write_model(@table_count);

        testing::set_account_contract_address(alice());
        testing::set_contract_address(alice());
        let table_id = contract.create_table(10, 20, 400, 2000, 6);

        // Alice joins
        contract.join_table(table_id, 1000);

        // Alice tries to join again
        contract.join_table(table_id, 1000);
    }

    #[test]
    #[should_panic(expected: ('Cannot join table', 'ENTRYPOINT_FAILED'))]
    fn test_join_full_table() {
        let (mut contract, mut world) = setup_test_contract();

        let table_count = TableCount { id: GAME_ID, count: 0 };
        world.write_model(@table_count);

        testing::set_account_contract_address(alice());
        testing::set_contract_address(alice());
        // Create table with only 2 seats
        let table_id = contract.create_table(10, 20, 400, 2000, 2);

        // Fill the table
        contract.join_table(table_id, 1000);

        testing::set_account_contract_address(bob());
        testing::set_contract_address(bob());
        contract.join_table(table_id, 1000);

        // Charlie tries to join full table
        testing::set_account_contract_address(charlie());
        testing::set_contract_address(charlie());
        contract.join_table(table_id, 1000);
    }

    #[test]
    fn test_leave_table_success() {
        let (mut contract, mut world) = setup_test_contract();

        // Setup table with players
        let table_count = TableCount { id: GAME_ID, count: 0 };
        world.write_model(@table_count);

        testing::set_account_contract_address(alice());
        testing::set_contract_address(alice());
        let table_id = contract.create_table(10, 20, 400, 2000, 6);
        contract.join_table(table_id, 1000);

        testing::set_account_contract_address(bob());
        testing::set_contract_address(bob());
        contract.join_table(table_id, 1000);

        // Verify 2 players
        let table_before: Table = world.read_model(table_id);
        assert(table_before.current_players == 2, 'should have 2 players');

        // Bob leaves
        contract.leave_table(table_id);

        // Verify Bob was removed
        let table_after: Table = world.read_model(table_id);
        assert(table_after.current_players == 1, 'should have 1 player');

        let table_players: TablePlayers = world.read_model(table_id);
        assert(table_players.player_count == 1, 'should have 1 in list');
    }

    #[test]
    #[should_panic(expected: ('Cannot leave during game', 'ENTRYPOINT_FAILED'))]
    fn test_leave_table_during_game() {
        let (mut contract, mut world) = setup_test_contract();

        let table_count = TableCount { id: GAME_ID, count: 0 };
        world.write_model(@table_count);

        testing::set_account_contract_address(alice());
        testing::set_contract_address(alice());
        let table_id = contract.create_table(10, 20, 400, 2000, 6);
        contract.join_table(table_id, 1000);

        testing::set_account_contract_address(zero());
        testing::set_contract_address(zero());
        // Manually set table to in progress
        let mut table: Table = world.read_model(table_id);
        table.status = GameStatus::InProgress.into();
        world.write_model(@table);

        // Try to leave during game
        contract.leave_table(table_id);
    }

    #[test]
    #[should_panic(expected: ('Player not found', 'ENTRYPOINT_FAILED'))]
    fn test_leave_table_not_at_table() {
        let (mut contract, mut world) = setup_test_contract();

        let table_count = TableCount { id: GAME_ID, count: 0 };
        world.write_model(@table_count);

        testing::set_account_contract_address(alice());
        testing::set_contract_address(alice());
        let table_id = contract.create_table(10, 20, 400, 2000, 6);

        // Bob tries to leave without joining
        testing::set_account_contract_address(bob());
        testing::set_contract_address(bob());
        contract.leave_table(table_id);
    }

    #[test]
    fn test_start_game_success() {
        let (mut contract, mut world) = setup_test_contract();

        // Setup table with enough players
        let table_count = TableCount { id: GAME_ID, count: 0 };
        world.write_model(@table_count);

        testing::set_account_contract_address(alice());
        testing::set_contract_address(alice());
        let table_id = contract.create_table(10, 20, 400, 2000, 6);
        contract.join_table(table_id, 1000);

        testing::set_account_contract_address(bob());
        testing::set_contract_address(bob());
        contract.join_table(table_id, 1000);

        // Alice (creator) starts the game
        testing::set_account_contract_address(alice());
        testing::set_contract_address(alice());
        contract.start_game(table_id);

        // Verify game started
        let table: Table = world.read_model(table_id);
        assert(table.status == GameStatus::InProgress.into(), 'should be in progress');
        assert(table.game_number == 1, 'should be game 1');
    }

    #[test]
    #[should_panic(expected: ('Only creator can start', 'ENTRYPOINT_FAILED'))]
    fn test_start_game_not_creator() {
        let (mut contract, mut world) = setup_test_contract();

        let table_count = TableCount { id: GAME_ID, count: 0 };
        world.write_model(@table_count);

        testing::set_account_contract_address(alice());
        testing::set_contract_address(alice());
        let table_id = contract.create_table(10, 20, 400, 2000, 6);
        contract.join_table(table_id, 1000);

        testing::set_account_contract_address(bob());
        testing::set_contract_address(bob());
        contract.join_table(table_id, 1000);

        // Bob tries to start (not creator)
        contract.start_game(table_id);
    }

    #[test]
    #[should_panic(expected: ('Cannot start game', 'ENTRYPOINT_FAILED'))]
    fn test_start_game_insufficient_players() {
        let (mut contract, mut world) = setup_test_contract();

        let table_count = TableCount { id: GAME_ID, count: 0 };
        world.write_model(@table_count);

        testing::set_account_contract_address(alice());
        testing::set_contract_address(alice());
        let table_id = contract.create_table(10, 20, 400, 2000, 6);
        contract.join_table(table_id, 1000);

        // Try to start with only 1 player
        contract.start_game(table_id);
    }

    #[test]
    fn test_get_table_info() {
        let (mut contract, mut world) = setup_test_contract();

        let table_count = TableCount { id: GAME_ID, count: 0 };
        world.write_model(@table_count);

        testing::set_account_contract_address(alice());
        testing::set_contract_address(alice());
        let table_id = contract.create_table(10, 20, 400, 2000, 6);

        let table_info = contract.get_table_info(table_id);
        assert(table_info.creator == alice(), 'wrong creator');
        assert(table_info.small_blind == 10, 'wrong small blind');
        assert(table_info.big_blind == 20, 'wrong big blind');
    }

    #[test]
    fn test_get_table_players() {
        let (mut contract, mut world) = setup_test_contract();

        let table_count = TableCount { id: GAME_ID, count: 0 };
        world.write_model(@table_count);

        testing::set_account_contract_address(alice());
        testing::set_contract_address(alice());
        let table_id = contract.create_table(10, 20, 400, 2000, 6);
        contract.join_table(table_id, 1000);

        testing::set_account_contract_address(bob());
        testing::set_contract_address(bob());
        contract.join_table(table_id, 1500);

        let table_players = contract.get_table_players(table_id);
        assert(table_players.player_count == 2, 'should have 2 players');
    }

    #[test]
    fn test_is_table_ready_to_start() {
        let (mut contract, mut world) = setup_test_contract();

        let table_count = TableCount { id: GAME_ID, count: 0 };
        world.write_model(@table_count);

        testing::set_account_contract_address(alice());
        testing::set_contract_address(alice());
        let table_id = contract.create_table(10, 20, 400, 2000, 6);

        // Not ready with 1 player
        contract.join_table(table_id, 1000);
        assert(!contract.is_table_ready_to_start(table_id), 'should not be ready');

        // Ready with 2 players
        testing::set_account_contract_address(bob());
        testing::set_contract_address(bob());
        contract.join_table(table_id, 1000);
        assert(contract.is_table_ready_to_start(table_id), 'should be ready');
    }

    #[test]
    fn test_is_player_at_table() {
        let mut table_players = TablePlayers {
            table_id: 1, players: array![alice(), bob()].span(), player_count: 2,
        };

        assert(
            TablePlayersTrait::is_player_at_table(@table_players, alice()),
            'alice should be at table',
        );
        assert(
            TablePlayersTrait::is_player_at_table(@table_players, bob()), 'bob should be at table',
        );
        assert(
            !TablePlayersTrait::is_player_at_table(@table_players, charlie()),
            'charlie should not be at table',
        );

        // Test empty table
        let empty_table = TablePlayers { table_id: 1, players: array![].span(), player_count: 0 };
        assert!(
            !TablePlayersTrait::is_player_at_table(@empty_table, alice()),
            "empty table should have no players",
        );
    }

    #[test]
    fn test_full_table_lifecycle() {
        let (mut contract, mut world) = setup_test_contract();

        // Initialize
        let table_count = TableCount { id: GAME_ID, count: 0 };
        world.write_model(@table_count);

        testing::set_account_contract_address(alice());
        testing::set_contract_address(alice());
        // Create table
        let table_id = contract.create_table(10, 20, 400, 2000, 4);

        // Players join
        contract.join_table(table_id, 1000);

        testing::set_account_contract_address(bob());
        testing::set_contract_address(bob());
        contract.join_table(table_id, 1000);

        testing::set_account_contract_address(charlie());
        testing::set_contract_address(charlie());
        contract.join_table(table_id, 1000);

        testing::set_account_contract_address(dave());
        testing::set_contract_address(dave());
        contract.join_table(table_id, 1000);

        // Verify table is full
        let table: Table = world.read_model(table_id);
        assert(table.current_players == 4, 'should have 4 players');
        assert(!table.can_join(), 'table should be full');

        // Table should be ready to start
        assert(contract.is_table_ready_to_start(table_id), 'should be ready to start');

        // Start game
        testing::set_account_contract_address(alice());
        testing::set_contract_address(alice());
        contract.start_game(table_id);

        // Verify game started
        let started_table: Table = world.read_model(table_id);
        assert(started_table.status == GameStatus::InProgress.into(), 'should be in progress');
        assert(started_table.game_number == 1, 'should be game 1');
    }

    #[test]
    fn test_multiple_tables() {
        let (mut contract, mut world) = setup_test_contract();

        let table_count = TableCount { id: GAME_ID, count: 0 };
        world.write_model(@table_count);

        testing::set_account_contract_address(alice());
        testing::set_contract_address(alice());
        // Create multiple tables
        let table1 = contract.create_table(5, 10, 200, 1000, 6);
        let table2 = contract.create_table(10, 20, 400, 2000, 4);

        testing::set_account_contract_address(bob());
        testing::set_contract_address(bob());
        let table3 = contract.create_table(25, 50, 1000, 5000, 8);

        // Verify unique IDs
        assert(table1 == 1, 'table1 should be id 1');
        assert(table2 == 2, 'table2 should be id 2');
        assert(table3 == 3, 'table3 should be id 3');

        // Verify each table has correct settings
        let t1_info = contract.get_table_info(table1);
        assert(t1_info.creator == alice(), 'wrong table1 creator');
        assert(t1_info.big_blind == 10, 'wrong table1 bb');

        let t2_info = contract.get_table_info(table2);
        assert(t2_info.creator == alice(), 'wrong table2 creator');
        assert(t2_info.big_blind == 20, 'wrong table2 bb');

        let t3_info = contract.get_table_info(table3);
        assert(t3_info.creator == bob(), 'wrong table3 creator');
        assert(t3_info.big_blind == 50, 'wrong table3 bb');

        // Players can join different tables
        testing::set_account_contract_address(alice());
        testing::set_contract_address(alice());
        contract.join_table(table1, 500);

        testing::set_account_contract_address(bob());
        testing::set_contract_address(bob());
        contract.join_table(table2, 800);

        testing::set_account_contract_address(charlie());
        testing::set_contract_address(charlie());
        contract.join_table(table3, 2000);

        // Verify independent table states
        let t1_after = contract.get_table_info(table1);
        let t2_after = contract.get_table_info(table2);
        let t3_after = contract.get_table_info(table3);

        assert(t1_after.current_players == 1, 'table1 should have 1 player');
        assert(t2_after.current_players == 1, 'table2 should have 1 player');
        assert(t3_after.current_players == 1, 'table3 should have 1 player');
    }

    #[test]
    fn test_table_count_persistence() {
        let (mut contract, mut world) = setup_test_contract();

        let table_count = TableCount { id: GAME_ID, count: 0 };
        world.write_model(@table_count);

        testing::set_account_contract_address(alice());
        testing::set_contract_address(alice());
        // Create tables and verify count increases
        let table1 = contract.create_table(10, 20, 400, 2000, 6);
        let count_after_1: TableCount = world.read_model(GAME_ID);
        assert(count_after_1.count == 1, 'count should be 1');

        let table2 = contract.create_table(10, 20, 400, 2000, 6);
        let count_after_2: TableCount = world.read_model(GAME_ID);
        assert(count_after_2.count == 2, 'count should be 2');

        let table3 = contract.create_table(10, 20, 400, 2000, 6);
        let count_after_3: TableCount = world.read_model(GAME_ID);
        assert(count_after_3.count == 3, 'count should be 3');

        // Verify table IDs are sequential
        assert(table1 == 1, 'first table should be 1');
        assert(table2 == 2, 'second table should be 2');
        assert(table3 == 3, 'third table should be 3');
    }

    #[test]
    fn test_table_state_transitions() {
        let (mut contract, mut world) = setup_test_contract();

        let table_count = TableCount { id: GAME_ID, count: 0 };
        world.write_model(@table_count);

        testing::set_account_contract_address(alice());
        testing::set_contract_address(alice());
        let table_id = contract.create_table(10, 20, 400, 2000, 6);

        // Initial state should be Waiting
        let table_initial = contract.get_table_info(table_id);
        assert(table_initial.status == GameStatus::Waiting.into(), 'should start waiting');

        // Add players
        contract.join_table(table_id, 1000);
        testing::set_account_contract_address(bob());
        testing::set_contract_address(bob());
        contract.join_table(table_id, 1000);

        // Should still be waiting until game starts
        let table_with_players = contract.get_table_info(table_id);
        assert(table_with_players.status == GameStatus::Waiting.into(), 'should still be waiting');

        // Start game - should transition to InProgress
        testing::set_account_contract_address(alice());
        testing::set_contract_address(alice());
        contract.start_game(table_id);

        let table_started = contract.get_table_info(table_id);
        assert(table_started.status == GameStatus::InProgress.into(), 'should be in progress');
    }

    #[test]
    fn test_buy_in_boundary_conditions() {
        let (mut contract, mut world) = setup_test_contract();

        let table_count = TableCount { id: GAME_ID, count: 0 };
        world.write_model(@table_count);

        testing::set_account_contract_address(alice());
        testing::set_contract_address(alice());
        let table_id = contract.create_table(10, 20, 400, 2000, 6);

        // Test minimum buy-in
        contract.join_table(table_id, 400); // Exactly minimum

        testing::set_account_contract_address(bob());
        testing::set_contract_address(bob());
        contract.join_table(table_id, 2000); // Exactly maximum

        // Verify both players joined successfully
        let table = contract.get_table_info(table_id);
        assert(table.current_players == 2, 'should have 2 players');

        let alice_player: Player = world.read_model((alice(), table_id));
        let bob_player: Player = world.read_model((bob(), table_id));

        assert(alice_player.stack == 400, 'alice wrong stack');
        assert(bob_player.stack == 2000, 'bob wrong stack');
    }

    #[test]
    fn test_position_assignment() {
        let (mut contract, mut world) = setup_test_contract();

        let table_count = TableCount { id: GAME_ID, count: 0 };
        world.write_model(@table_count);

        testing::set_account_contract_address(alice());
        testing::set_contract_address(alice());
        let table_id = contract.create_table(10, 20, 400, 2000, 6);

        // Players join in order
        contract.join_table(table_id, 1000);

        testing::set_account_contract_address(bob());
        testing::set_contract_address(bob());
        contract.join_table(table_id, 1000);

        testing::set_account_contract_address(charlie());
        testing::set_contract_address(charlie());
        contract.join_table(table_id, 1000);

        testing::set_account_contract_address(dave());
        testing::set_contract_address(dave());
        contract.join_table(table_id, 1000);

        // Verify positions are assigned correctly
        let alice_player: Player = world.read_model((alice(), table_id));
        let bob_player: Player = world.read_model((bob(), table_id));
        let charlie_player: Player = world.read_model((charlie(), table_id));
        let dave_player: Player = world.read_model((dave(), table_id));

        assert(alice_player.position == 0, 'alice wrong position');
        assert(bob_player.position == 1, 'bob wrong position');
        assert(charlie_player.position == 2, 'charlie wrong position');
        assert(dave_player.position == 3, 'dave wrong position');
    }

    #[test]
    fn test_max_players_at_table() {
        let (mut contract, mut world) = setup_test_contract();

        let table_count = TableCount { id: GAME_ID, count: 0 };
        world.write_model(@table_count);

        testing::set_account_contract_address(alice());
        testing::set_contract_address(alice());
        // Create table with max players (10)
        let table_id = contract.create_table(10, 20, 400, 2000, 10);

        // Add players up to maximum
        let players = array![
            alice(),
            bob(),
            charlie(),
            dave(),
            contract_address_const::<0x5>(),
            contract_address_const::<0x6>(),
            contract_address_const::<0x7>(),
            contract_address_const::<0x8>(),
            contract_address_const::<0x9>(),
            contract_address_const::<0xA>(),
        ];

        let mut i = 0;
        while i < players.len() {
            testing::set_contract_address(*players.at(i));
            contract.join_table(table_id, 1000);
            i += 1;
        };

        // Verify table is full
        let table = contract.get_table_info(table_id);
        assert(table.current_players == 10, 'should have 10 players');
        assert(!table.can_join(), 'should not accept more');

        // Verify all players are in the table
        let table_players = contract.get_table_players(table_id);
        assert(table_players.player_count == 10, 'should have 10 in list');
    }

    #[test]
    fn test_rapid_join_leave_sequence() {
        let (mut contract, mut world) = setup_test_contract();

        let table_count = TableCount { id: GAME_ID, count: 0 };
        world.write_model(@table_count);

        testing::set_account_contract_address(alice());
        testing::set_contract_address(alice());
        let table_id = contract.create_table(10, 20, 400, 2000, 6);

        // Rapid join/leave sequence
        contract.join_table(table_id, 1000);

        testing::set_account_contract_address(bob());
        testing::set_contract_address(bob());
        contract.join_table(table_id, 1000);
        contract.leave_table(table_id);

        testing::set_account_contract_address(charlie());
        testing::set_contract_address(charlie());
        contract.join_table(table_id, 1000);

        testing::set_account_contract_address(bob());
        testing::set_contract_address(bob());
        contract.join_table(table_id, 1500); // Bob rejoins with different buy-in

        // Verify final state
        let table = contract.get_table_info(table_id);
        assert(table.current_players == 3, 'should have 3 players');

        let table_players = contract.get_table_players(table_id);
        assert(table_players.player_count == 3, 'should have 3 in list');

        // Verify Bob's new buy-in
        let bob_player: Player = world.read_model((bob(), table_id));
        assert(bob_player.stack == 1500, 'bob should have new stack');
    }

    #[test]
    fn test_game_ready_transitions() {
        let (mut contract, mut world) = setup_test_contract();

        let table_count = TableCount { id: GAME_ID, count: 0 };
        world.write_model(@table_count);

        testing::set_account_contract_address(alice());
        testing::set_contract_address(alice());
        let table_id = contract.create_table(10, 20, 400, 2000, 6);

        // Not ready with 1 player
        contract.join_table(table_id, 1000);
        assert(!contract.is_table_ready_to_start(table_id), 'not ready with 1');

        // Ready with 2 players
        testing::set_account_contract_address(bob());
        testing::set_contract_address(bob());
        contract.join_table(table_id, 1000);
        assert(contract.is_table_ready_to_start(table_id), 'ready with 2');

        // Still ready with more players
        testing::set_account_contract_address(charlie());
        testing::set_contract_address(charlie());
        contract.join_table(table_id, 1000);
        assert(contract.is_table_ready_to_start(table_id), 'ready with 3');

        // Not ready after player leaves (if it goes below 2)
        testing::set_account_contract_address(charlie());
        testing::set_contract_address(charlie());
        contract.leave_table(table_id);
        assert(contract.is_table_ready_to_start(table_id), 'still ready with 2');

        testing::set_account_contract_address(bob());
        testing::set_contract_address(bob());
        contract.leave_table(table_id);
        assert(!contract.is_table_ready_to_start(table_id), 'not ready with 1');
    }
}

