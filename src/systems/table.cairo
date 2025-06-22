use poker_game::models::table::{Table, TablePlayers};

#[starknet::interface]
pub trait ITableSystems<T> {
    fn create_table(
        ref self: T,
        small_blind: u128,
        big_blind: u128,
        min_buy_in: u128,
        max_buy_in: u128,
        max_players: u8,
    ) -> u32;
    fn join_table(ref self: T, table_id: u32, buy_in: u128);
    fn leave_table(ref self: T, table_id: u32);
    fn start_game(ref self: T, table_id: u32);
    fn get_table_info(self: @T, table_id: u32) -> Table;
    fn get_table_players(self: @T, table_id: u32) -> TablePlayers;
    fn is_table_ready_to_start(self: @T, table_id: u32) -> bool;
}

// dojo decorator
#[dojo::contract]
pub mod table_systems {
    use super::*;
    use starknet::{ContractAddress, get_caller_address};
    use poker_game::models::table::{
        TableTrait, TableCount, TableCountImpl, TableCountTrait, TablePlayers, Table,
        TablePlayersTrait, GameStatus,
    };
    use poker_game::models::player::{PlayerTrait, Player};
    use poker_game::constants::{GAME_ID};

    use dojo::model::{ModelStorage};
    use dojo::event::EventStorage;

    #[derive(Drop, Copy, Serde)]
    #[dojo::event]
    pub struct GameStarted {
        #[key]
        pub table_id: u32,
        #[key]
        pub game_number: u32,
        pub dealer_position: u8,
        pub players: Span<ContractAddress>,
    }

    #[derive(Drop, Copy, Serde)]
    #[dojo::event]
    pub struct PlayerJoinedTable {
        #[key]
        pub table_id: u32,
        #[key]
        pub player: ContractAddress,
        pub position: u8,
        pub buy_in: u128,
    }

    #[derive(Drop, Copy, Serde)]
    #[dojo::event]
    pub struct PlayerLeaveTable {
        #[key]
        pub table_id: u32,
        pub player: ContractAddress,
        // pub position: u8,
    // pub buy_in: u128,
    }

    #[derive(Drop, Copy, Serde)]
    #[dojo::event]
    pub struct TableCreated {
        #[key]
        pub table_id: u32,
        pub creator: ContractAddress,
        pub small_blind: u128,
        pub big_blind: u128,
        pub max_players: u8,
    }

    #[derive(Drop, Copy, Serde)]
    #[dojo::event]
    pub struct GameReadyToStart {
        #[key]
        pub table_id: u32,
        pub player_count: u8,
    }

    #[abi(embed_v0)]
    impl TableSystemsImpl of ITableSystems<ContractState> {
        fn create_table(
            ref self: ContractState,
            small_blind: u128,
            big_blind: u128,
            min_buy_in: u128,
            max_buy_in: u128,
            max_players: u8,
        ) -> u32 {
            let mut world = self.world_default();
            let caller = get_caller_address();

            let mut table_count: TableCount = world.read_model(GAME_ID);
            let table_id = table_count.get_next_table_id();

            // validation
            assert(big_blind > small_blind, 'BB must be > SB');
            assert(max_buy_in >= min_buy_in, 'Max buy-in must be >= min');
            assert(max_players >= 2 && max_players <= 10, 'Invalid max players');
            assert(min_buy_in >= big_blind * 20, 'Min buy-in too small');
            assert(small_blind > 0, 'Small blind must be > 0');

            // Create table
            let table = TableTrait::new(
                table_id, caller, small_blind, big_blind, min_buy_in, max_buy_in, max_players,
            );

            // Initialize empty player list
            let table_players = TablePlayers {
                table_id, players: array![].span(), player_count: 0,
            };

            // Write to world
            world.write_model(@table);
            world.write_model(@table_players);
            world.write_model(@table_count);

            // Emit table creation event
            world
                .emit_event(
                    @TableCreated {
                        table_id, creator: caller, small_blind, big_blind, max_players,
                    },
                );

            table_id
        }

        fn join_table(ref self: ContractState, table_id: u32, buy_in: u128) {
            let mut world = self.world_default();
            let caller = get_caller_address();

            let mut table: Table = world.read_model(table_id);
            let mut table_players: TablePlayers = world.read_model(table_id);

            // validation
            assert(table.can_join(), 'Cannot join table');
            assert(
                buy_in >= table.min_buy_in && buy_in <= table.max_buy_in, 'Invalid buy-in amount',
            );
            assert(
                !TablePlayersTrait::is_player_at_table(@table_players, caller),
                'Player already at table',
            );

            // Create player
            let player = PlayerTrait::new(caller, table_id, buy_in, table.current_players);

            // Update table and players
            assert(table.add_player(), 'Failed to add player');
            table_players.add_player(caller);

            // Write updates
            world.write_model(@table);
            world.write_model(@table_players);
            world.write_model(@player);

            // Emit join event
            world
                .emit_event(
                    @PlayerJoinedTable {
                        table_id, player: caller, position: player.position, buy_in,
                    },
                );

            // Check if ready to start
            if table.can_start_game() {
                world
                    .emit_event(
                        @GameReadyToStart { table_id, player_count: table.current_players },
                    );
            }
        }

        fn leave_table(ref self: ContractState, table_id: u32) {
            let mut world = self.world_default();
            let caller = get_caller_address();

            let mut table: Table = world.read_model(table_id);
            let mut table_players: TablePlayers = world.read_model(table_id);
            let player: Player = world.read_model((caller, table_id));

            // validation
            assert(table.status == GameStatus::Waiting.into(), 'Cannot leave during game');
            assert(
                TablePlayersTrait::is_player_at_table(@table_players, caller), 'Player not found',
            );
            assert(table.current_players > 0, 'No players to remove');

            // Remove player from table
            table.current_players -= 1;
            self.remove_player(ref table_players, caller);

            // TODO: Handle chip redistribution if needed

            // Write updates
            world.write_model(@table);
            world.write_model(@table_players);

            // Emit leave event
            world.emit_event(@PlayerLeaveTable { table_id, player: caller });
        }

        fn start_game(ref self: ContractState, table_id: u32) {
            let mut world = self.world_default();
            let caller = get_caller_address();

            let mut table: Table = world.read_model(table_id);
            let table_players: TablePlayers = world.read_model(table_id);

            // Validation
            assert(table.creator == caller, 'Only creator can start');
            assert(table.can_start_game(), 'Cannot start game');

            // Start the game
            assert(table.start_game(), 'Failed to start game');

            // Write updated table
            world.write_model(@table);

            // Emit game started event
            world
                .emit_event(
                    @GameStarted {
                        table_id,
                        game_number: table.game_number,
                        dealer_position: table.dealer_position,
                        players: table_players.players,
                    },
                );
        }

        fn get_table_info(self: @ContractState, table_id: u32) -> Table {
            let world = self.world_default();
            world.read_model(table_id)
        }

        fn get_table_players(self: @ContractState, table_id: u32) -> TablePlayers {
            let world = self.world_default();
            world.read_model(table_id)
        }

        fn is_table_ready_to_start(self: @ContractState, table_id: u32) -> bool {
            let world = self.world_default();
            let table: Table = world.read_model(table_id);
            table.can_start_game()
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn world_default(self: @ContractState) -> dojo::world::WorldStorage {
            self.world(@"poker_game")
        }

        fn remove_player(
            ref self: ContractState, ref table_players: TablePlayers, player: ContractAddress,
        ) {
            let mut new_players: Array<ContractAddress> = array![];
            let mut found = false;
            let mut i = 0;

            // Rebuild array without the leaving player
            while i < table_players.player_count {
                let current_player = *table_players.players.at(i.into());
                if current_player != player {
                    new_players.append(current_player);
                } else {
                    found = true;
                }
                i += 1;
            };

            if found {
                table_players.players = new_players.span();
                table_players.player_count -= 1;

                // update all remaining players' positions
                self.update_player_positions_after_removal(ref table_players);
            } else {
                assert(false, 'Player not found');
            }
        }

        fn update_player_positions_after_removal(
            ref self: ContractState, ref table_players: TablePlayers,
        ) {
            let mut world = self.world_default();

            for i in 0..table_players.player_count {
                let player_address = *table_players.players.at(i.into());
                let mut player: Player = world.read_model((player_address, table_players.table_id));
                player.position = i.into();
                world.write_model(@player);
            }
        }
    }
}
