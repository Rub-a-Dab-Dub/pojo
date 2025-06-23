import { DojoProvider, DojoCall } from "@dojoengine/core";
import { Account, AccountInterface, BigNumberish, CairoOption, CairoCustomEnum, ByteArray } from "starknet";
import * as models from "./models.gen";

export function setupWorld(provider: DojoProvider) {

	const build_game_systems_advanceBettingRound_calldata = (tableId: BigNumberish): DojoCall => {
		return {
			contractName: "game_systems",
			entrypoint: "advance_betting_round",
			calldata: [tableId],
		};
	};

	const game_systems_advanceBettingRound = async (snAccount: Account | AccountInterface, tableId: BigNumberish) => {
		try {
			return await provider.execute(
				snAccount,
				build_game_systems_advanceBettingRound_calldata(tableId),
				"pojo",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_game_systems_canPlayerAct_calldata = (tableId: BigNumberish, player: string): DojoCall => {
		return {
			contractName: "game_systems",
			entrypoint: "can_player_act",
			calldata: [tableId, player],
		};
	};

	const game_systems_canPlayerAct = async (tableId: BigNumberish, player: string) => {
		try {
			return await provider.call("pojo", build_game_systems_canPlayerAct_calldata(tableId, player));
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_game_systems_checkRoundComplete_calldata = (tableId: BigNumberish): DojoCall => {
		return {
			contractName: "game_systems",
			entrypoint: "check_round_complete",
			calldata: [tableId],
		};
	};

	const game_systems_checkRoundComplete = async (tableId: BigNumberish) => {
		try {
			return await provider.call("pojo", build_game_systems_checkRoundComplete_calldata(tableId));
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_table_systems_createTable_calldata = (smallBlind: BigNumberish, bigBlind: BigNumberish, minBuyIn: BigNumberish, maxBuyIn: BigNumberish, maxPlayers: BigNumberish): DojoCall => {
		return {
			contractName: "table_systems",
			entrypoint: "create_table",
			calldata: [smallBlind, bigBlind, minBuyIn, maxBuyIn, maxPlayers],
		};
	};

	const table_systems_createTable = async (snAccount: Account | AccountInterface, smallBlind: BigNumberish, bigBlind: BigNumberish, minBuyIn: BigNumberish, maxBuyIn: BigNumberish, maxPlayers: BigNumberish) => {
		try {
			return await provider.execute(
				snAccount,
				build_table_systems_createTable_calldata(smallBlind, bigBlind, minBuyIn, maxBuyIn, maxPlayers),
				"pojo",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_game_systems_dealFlop_calldata = (tableId: BigNumberish): DojoCall => {
		return {
			contractName: "game_systems",
			entrypoint: "deal_flop",
			calldata: [tableId],
		};
	};

	const game_systems_dealFlop = async (snAccount: Account | AccountInterface, tableId: BigNumberish) => {
		try {
			return await provider.execute(
				snAccount,
				build_game_systems_dealFlop_calldata(tableId),
				"pojo",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_game_systems_dealHoleCards_calldata = (tableId: BigNumberish): DojoCall => {
		return {
			contractName: "game_systems",
			entrypoint: "deal_hole_cards",
			calldata: [tableId],
		};
	};

	const game_systems_dealHoleCards = async (snAccount: Account | AccountInterface, tableId: BigNumberish) => {
		try {
			return await provider.execute(
				snAccount,
				build_game_systems_dealHoleCards_calldata(tableId),
				"pojo",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_game_systems_dealRiver_calldata = (tableId: BigNumberish): DojoCall => {
		return {
			contractName: "game_systems",
			entrypoint: "deal_river",
			calldata: [tableId],
		};
	};

	const game_systems_dealRiver = async (snAccount: Account | AccountInterface, tableId: BigNumberish) => {
		try {
			return await provider.execute(
				snAccount,
				build_game_systems_dealRiver_calldata(tableId),
				"pojo",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_game_systems_dealTurn_calldata = (tableId: BigNumberish): DojoCall => {
		return {
			contractName: "game_systems",
			entrypoint: "deal_turn",
			calldata: [tableId],
		};
	};

	const game_systems_dealTurn = async (snAccount: Account | AccountInterface, tableId: BigNumberish) => {
		try {
			return await provider.execute(
				snAccount,
				build_game_systems_dealTurn_calldata(tableId),
				"pojo",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_game_systems_distributePot_calldata = (tableId: BigNumberish): DojoCall => {
		return {
			contractName: "game_systems",
			entrypoint: "distribute_pot",
			calldata: [tableId],
		};
	};

	const game_systems_distributePot = async (snAccount: Account | AccountInterface, tableId: BigNumberish) => {
		try {
			return await provider.execute(
				snAccount,
				build_game_systems_distributePot_calldata(tableId),
				"pojo",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_game_systems_evaluateHands_calldata = (tableId: BigNumberish): DojoCall => {
		return {
			contractName: "game_systems",
			entrypoint: "evaluate_hands",
			calldata: [tableId],
		};
	};

	const game_systems_evaluateHands = async (snAccount: Account | AccountInterface, tableId: BigNumberish) => {
		try {
			return await provider.execute(
				snAccount,
				build_game_systems_evaluateHands_calldata(tableId),
				"pojo",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_game_systems_getActivePlayers_calldata = (tableId: BigNumberish): DojoCall => {
		return {
			contractName: "game_systems",
			entrypoint: "get_active_players",
			calldata: [tableId],
		};
	};

	const game_systems_getActivePlayers = async (tableId: BigNumberish) => {
		try {
			return await provider.call("pojo", build_game_systems_getActivePlayers_calldata(tableId));
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_game_systems_getCurrentBet_calldata = (tableId: BigNumberish): DojoCall => {
		return {
			contractName: "game_systems",
			entrypoint: "get_current_bet",
			calldata: [tableId],
		};
	};

	const game_systems_getCurrentBet = async (tableId: BigNumberish) => {
		try {
			return await provider.call("pojo", build_game_systems_getCurrentBet_calldata(tableId));
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_game_systems_getPlayerToAct_calldata = (tableId: BigNumberish): DojoCall => {
		return {
			contractName: "game_systems",
			entrypoint: "get_player_to_act",
			calldata: [tableId],
		};
	};

	const game_systems_getPlayerToAct = async (tableId: BigNumberish) => {
		try {
			return await provider.call("pojo", build_game_systems_getPlayerToAct_calldata(tableId));
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_table_systems_getTableInfo_calldata = (tableId: BigNumberish): DojoCall => {
		return {
			contractName: "table_systems",
			entrypoint: "get_table_info",
			calldata: [tableId],
		};
	};

	const table_systems_getTableInfo = async (tableId: BigNumberish) => {
		try {
			return await provider.call("pojo", build_table_systems_getTableInfo_calldata(tableId));
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_table_systems_getTablePlayers_calldata = (tableId: BigNumberish): DojoCall => {
		return {
			contractName: "table_systems",
			entrypoint: "get_table_players",
			calldata: [tableId],
		};
	};

	const table_systems_getTablePlayers = async (tableId: BigNumberish) => {
		try {
			return await provider.call("pojo", build_table_systems_getTablePlayers_calldata(tableId));
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_table_systems_isTableReadyToStart_calldata = (tableId: BigNumberish): DojoCall => {
		return {
			contractName: "table_systems",
			entrypoint: "is_table_ready_to_start",
			calldata: [tableId],
		};
	};

	const table_systems_isTableReadyToStart = async (tableId: BigNumberish) => {
		try {
			return await provider.call("pojo", build_table_systems_isTableReadyToStart_calldata(tableId));
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_table_systems_joinTable_calldata = (tableId: BigNumberish, buyIn: BigNumberish): DojoCall => {
		return {
			contractName: "table_systems",
			entrypoint: "join_table",
			calldata: [tableId, buyIn],
		};
	};

	const table_systems_joinTable = async (snAccount: Account | AccountInterface, tableId: BigNumberish, buyIn: BigNumberish) => {
		try {
			return await provider.execute(
				snAccount,
				build_table_systems_joinTable_calldata(tableId, buyIn),
				"pojo",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_table_systems_leaveTable_calldata = (tableId: BigNumberish): DojoCall => {
		return {
			contractName: "table_systems",
			entrypoint: "leave_table",
			calldata: [tableId],
		};
	};

	const table_systems_leaveTable = async (snAccount: Account | AccountInterface, tableId: BigNumberish) => {
		try {
			return await provider.execute(
				snAccount,
				build_table_systems_leaveTable_calldata(tableId),
				"pojo",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_game_systems_playerAction_calldata = (tableId: BigNumberish, action: CairoCustomEnum, amount: BigNumberish): DojoCall => {
		return {
			contractName: "game_systems",
			entrypoint: "player_action",
			calldata: [tableId, action, amount],
		};
	};

	const game_systems_playerAction = async (snAccount: Account | AccountInterface, tableId: BigNumberish, action: CairoCustomEnum, amount: BigNumberish) => {
		try {
			return await provider.execute(
				snAccount,
				build_game_systems_playerAction_calldata(tableId, action, amount),
				"pojo",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_game_systems_postBlinds_calldata = (tableId: BigNumberish): DojoCall => {
		return {
			contractName: "game_systems",
			entrypoint: "post_blinds",
			calldata: [tableId],
		};
	};

	const game_systems_postBlinds = async (snAccount: Account | AccountInterface, tableId: BigNumberish) => {
		try {
			return await provider.execute(
				snAccount,
				build_game_systems_postBlinds_calldata(tableId),
				"pojo",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_game_systems_shuffleDeck_calldata = (tableId: BigNumberish, seed: BigNumberish): DojoCall => {
		return {
			contractName: "game_systems",
			entrypoint: "shuffle_deck",
			calldata: [tableId, seed],
		};
	};

	const game_systems_shuffleDeck = async (snAccount: Account | AccountInterface, tableId: BigNumberish, seed: BigNumberish) => {
		try {
			return await provider.execute(
				snAccount,
				build_game_systems_shuffleDeck_calldata(tableId, seed),
				"pojo",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_table_systems_startGame_calldata = (tableId: BigNumberish): DojoCall => {
		return {
			contractName: "table_systems",
			entrypoint: "start_game",
			calldata: [tableId],
		};
	};

	const table_systems_startGame = async (snAccount: Account | AccountInterface, tableId: BigNumberish) => {
		try {
			return await provider.execute(
				snAccount,
				build_table_systems_startGame_calldata(tableId),
				"pojo",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};



	return {
		game_systems: {
			advanceBettingRound: game_systems_advanceBettingRound,
			buildAdvanceBettingRoundCalldata: build_game_systems_advanceBettingRound_calldata,
			canPlayerAct: game_systems_canPlayerAct,
			buildCanPlayerActCalldata: build_game_systems_canPlayerAct_calldata,
			checkRoundComplete: game_systems_checkRoundComplete,
			buildCheckRoundCompleteCalldata: build_game_systems_checkRoundComplete_calldata,
			dealFlop: game_systems_dealFlop,
			buildDealFlopCalldata: build_game_systems_dealFlop_calldata,
			dealHoleCards: game_systems_dealHoleCards,
			buildDealHoleCardsCalldata: build_game_systems_dealHoleCards_calldata,
			dealRiver: game_systems_dealRiver,
			buildDealRiverCalldata: build_game_systems_dealRiver_calldata,
			dealTurn: game_systems_dealTurn,
			buildDealTurnCalldata: build_game_systems_dealTurn_calldata,
			distributePot: game_systems_distributePot,
			buildDistributePotCalldata: build_game_systems_distributePot_calldata,
			evaluateHands: game_systems_evaluateHands,
			buildEvaluateHandsCalldata: build_game_systems_evaluateHands_calldata,
			getActivePlayers: game_systems_getActivePlayers,
			buildGetActivePlayersCalldata: build_game_systems_getActivePlayers_calldata,
			getCurrentBet: game_systems_getCurrentBet,
			buildGetCurrentBetCalldata: build_game_systems_getCurrentBet_calldata,
			getPlayerToAct: game_systems_getPlayerToAct,
			buildGetPlayerToActCalldata: build_game_systems_getPlayerToAct_calldata,
			playerAction: game_systems_playerAction,
			buildPlayerActionCalldata: build_game_systems_playerAction_calldata,
			postBlinds: game_systems_postBlinds,
			buildPostBlindsCalldata: build_game_systems_postBlinds_calldata,
			shuffleDeck: game_systems_shuffleDeck,
			buildShuffleDeckCalldata: build_game_systems_shuffleDeck_calldata,
		},
		table_systems: {
			createTable: table_systems_createTable,
			buildCreateTableCalldata: build_table_systems_createTable_calldata,
			getTableInfo: table_systems_getTableInfo,
			buildGetTableInfoCalldata: build_table_systems_getTableInfo_calldata,
			getTablePlayers: table_systems_getTablePlayers,
			buildGetTablePlayersCalldata: build_table_systems_getTablePlayers_calldata,
			isTableReadyToStart: table_systems_isTableReadyToStart,
			buildIsTableReadyToStartCalldata: build_table_systems_isTableReadyToStart_calldata,
			joinTable: table_systems_joinTable,
			buildJoinTableCalldata: build_table_systems_joinTable_calldata,
			leaveTable: table_systems_leaveTable,
			buildLeaveTableCalldata: build_table_systems_leaveTable_calldata,
			startGame: table_systems_startGame,
			buildStartGameCalldata: build_table_systems_startGame_calldata,
		},
	};
}