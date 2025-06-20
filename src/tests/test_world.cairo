// #[cfg(test)]
// mod tests {
//     use dojo_cairo_test::WorldStorageTestTrait;
//     use dojo::model::{ModelStorage, ModelStorageTest};
//     use dojo::world::WorldStorageTrait;
//     use dojo_cairo_test::{
//         spawn_test_world, NamespaceDef, TestResource, ContractDefTrait, ContractDef,
//     };

//     use poker_game::systems::actions::{actions, IActionsDispatcher, IActionsDispatcherTrait};
//     use poker_game::models::{Position, m_Position, Moves, m_Moves, Direction};

//     fn namespace_def() -> NamespaceDef {
//         let ndef = NamespaceDef {
//             namespace: "poker_game",
//             resources: [
//                 TestResource::Model(m_Position::TEST_CLASS_HASH),
//                 TestResource::Model(m_Moves::TEST_CLASS_HASH),
//                 TestResource::Event(actions::e_Moved::TEST_CLASS_HASH),
//                 TestResource::Contract(actions::TEST_CLASS_HASH),
//             ]
//                 .span(),
//         };

//         ndef
//     }

//     fn contract_defs() -> Span<ContractDef> {
//         [
//             ContractDefTrait::new(@"poker_game", @"actions")
//                 .with_writer_of([dojo::utils::bytearray_hash(@"poker_game")].span())
//         ]
//             .span()
//     }

//     #[test]
//     fn test_world_test_set() {
//         // Initialize test environment
//         let caller = starknet::contract_address_const::<0x0>();
//         let ndef = namespace_def();

//         // Register the resources.
//         let mut world = spawn_test_world([ndef].span());

//         // Ensures permissions and initializations are synced.
//         world.sync_perms_and_inits(contract_defs());

//     }}
