
#[starknet::interface]
pub trait IActions<T> {

}

// dojo decorator
#[dojo::contract]
pub mod actions {
    use super::*;
    // use starknet::{ContractAddress, get_caller_address};
    // use poker_game::models::{Vec2, Moves};

    // use dojo::model::{ModelStorage};
    // use dojo::event::EventStorage;

    #[abi(embed_v0)]
    impl ActionsImpl of IActions<ContractState> {
       
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        /// Use the default namespace "poker_game". This function is handy since the ByteArray
        /// can't be const.
        fn world_default(self: @ContractState) -> dojo::world::WorldStorage {
            self.world(@"poker_game")
        }
    }
}
