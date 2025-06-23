import type { SchemaType as ISchemaType } from "@dojoengine/sdk";

import { BigNumberish } from 'starknet';

// Type definition for `pojo::models::player::Player` struct
export interface Player {
	address: string;
	table_id: BigNumberish;
	stack: BigNumberish;
	current_bet: BigNumberish;
	hole_card1: BigNumberish;
	hole_card2: BigNumberish;
	is_active: boolean;
	has_acted: boolean;
	position: BigNumberish;
	last_action: BigNumberish;
}

// Type definition for `pojo::models::player::PlayerValue` struct
export interface PlayerValue {
	stack: BigNumberish;
	current_bet: BigNumberish;
	hole_card1: BigNumberish;
	hole_card2: BigNumberish;
	is_active: boolean;
	has_acted: boolean;
	position: BigNumberish;
	last_action: BigNumberish;
}

// Type definition for `pojo::models::table::CommunityCards` struct
export interface CommunityCards {
	table_id: BigNumberish;
	game_number: BigNumberish;
	flop1: BigNumberish;
	flop2: BigNumberish;
	flop3: BigNumberish;
	turn: BigNumberish;
	river: BigNumberish;
	cards_dealt: BigNumberish;
}

// Type definition for `pojo::models::table::CommunityCardsValue` struct
export interface CommunityCardsValue {
	flop1: BigNumberish;
	flop2: BigNumberish;
	flop3: BigNumberish;
	turn: BigNumberish;
	river: BigNumberish;
	cards_dealt: BigNumberish;
}

// Type definition for `pojo::models::table::GameDeck` struct
export interface GameDeck {
	table_id: BigNumberish;
	game_number: BigNumberish;
	cards: Array<BigNumberish>;
	next_card_index: BigNumberish;
	seed: BigNumberish;
}

// Type definition for `pojo::models::table::GameDeckValue` struct
export interface GameDeckValue {
	cards: Array<BigNumberish>;
	next_card_index: BigNumberish;
	seed: BigNumberish;
}

// Type definition for `pojo::models::table::SidePot` struct
export interface SidePot {
	table_id: BigNumberish;
	game_number: BigNumberish;
	pot_id: BigNumberish;
	amount: BigNumberish;
	eligible_players: Array<string>;
}

// Type definition for `pojo::models::table::SidePotValue` struct
export interface SidePotValue {
	amount: BigNumberish;
	eligible_players: Array<string>;
}

// Type definition for `pojo::models::table::Table` struct
export interface Table {
	table_id: BigNumberish;
	creator: string;
	dealer_position: BigNumberish;
	small_blind: BigNumberish;
	big_blind: BigNumberish;
	min_buy_in: BigNumberish;
	max_buy_in: BigNumberish;
	max_players: BigNumberish;
	current_players: BigNumberish;
	status: BigNumberish;
	current_round: BigNumberish;
	pot_total: BigNumberish;
	current_bet: BigNumberish;
	current_player_position: BigNumberish;
	last_raise_amount: BigNumberish;
	players_acted_this_round: BigNumberish;
	game_number: BigNumberish;
}

// Type definition for `pojo::models::table::TableCount` struct
export interface TableCount {
	id: BigNumberish;
	count: BigNumberish;
}

// Type definition for `pojo::models::table::TableCountValue` struct
export interface TableCountValue {
	count: BigNumberish;
}

// Type definition for `pojo::models::table::TablePlayers` struct
export interface TablePlayers {
	table_id: BigNumberish;
	players: Array<string>;
	player_count: BigNumberish;
}

// Type definition for `pojo::models::table::TablePlayersValue` struct
export interface TablePlayersValue {
	players: Array<string>;
	player_count: BigNumberish;
}

// Type definition for `pojo::models::table::TableValue` struct
export interface TableValue {
	creator: string;
	dealer_position: BigNumberish;
	small_blind: BigNumberish;
	big_blind: BigNumberish;
	min_buy_in: BigNumberish;
	max_buy_in: BigNumberish;
	max_players: BigNumberish;
	current_players: BigNumberish;
	status: BigNumberish;
	current_round: BigNumberish;
	pot_total: BigNumberish;
	current_bet: BigNumberish;
	current_player_position: BigNumberish;
	last_raise_amount: BigNumberish;
	players_acted_this_round: BigNumberish;
	game_number: BigNumberish;
}

// Type definition for `pojo::systems::game::game_systems::BettingRoundComplete` struct
export interface BettingRoundComplete {
	table_id: BigNumberish;
	round: BigNumberish;
	pot_total: BigNumberish;
}

// Type definition for `pojo::systems::game::game_systems::BettingRoundCompleteValue` struct
export interface BettingRoundCompleteValue {
	round: BigNumberish;
	pot_total: BigNumberish;
}

// Type definition for `pojo::systems::game::game_systems::BlindsPosted` struct
export interface BlindsPosted {
	table_id: BigNumberish;
	small_blind_player: string;
	big_blind_player: string;
	small_blind_amount: BigNumberish;
	big_blind_amount: BigNumberish;
}

// Type definition for `pojo::systems::game::game_systems::BlindsPostedValue` struct
export interface BlindsPostedValue {
	small_blind_player: string;
	big_blind_player: string;
	small_blind_amount: BigNumberish;
	big_blind_amount: BigNumberish;
}

// Type definition for `pojo::systems::game::game_systems::CommunityCardsDealt` struct
export interface CommunityCardsDealt {
	table_id: BigNumberish;
	game_number: BigNumberish;
	round: BigNumberish;
	cards_dealt: BigNumberish;
}

// Type definition for `pojo::systems::game::game_systems::CommunityCardsDealtValue` struct
export interface CommunityCardsDealtValue {
	round: BigNumberish;
	cards_dealt: BigNumberish;
}

// Type definition for `pojo::systems::game::game_systems::HoleCardsDealt` struct
export interface HoleCardsDealt {
	table_id: BigNumberish;
	game_number: BigNumberish;
	player_count: BigNumberish;
}

// Type definition for `pojo::systems::game::game_systems::HoleCardsDealtValue` struct
export interface HoleCardsDealtValue {
	player_count: BigNumberish;
}

// Type definition for `pojo::systems::game::game_systems::PlayerActed` struct
export interface PlayerActed {
	table_id: BigNumberish;
	player: string;
	action: BigNumberish;
	amount: BigNumberish;
	pot_total: BigNumberish;
}

// Type definition for `pojo::systems::game::game_systems::PlayerActedValue` struct
export interface PlayerActedValue {
	action: BigNumberish;
	amount: BigNumberish;
	pot_total: BigNumberish;
}

// Type definition for `pojo::systems::game::game_systems::PotDistributed` struct
export interface PotDistributed {
	table_id: BigNumberish;
	winner: string;
	amount: BigNumberish;
	hand_rank: BigNumberish;
}

// Type definition for `pojo::systems::game::game_systems::PotDistributedValue` struct
export interface PotDistributedValue {
	amount: BigNumberish;
	hand_rank: BigNumberish;
}

// Type definition for `pojo::systems::table::table_systems::GameReadyToStart` struct
export interface GameReadyToStart {
	table_id: BigNumberish;
	player_count: BigNumberish;
}

// Type definition for `pojo::systems::table::table_systems::GameReadyToStartValue` struct
export interface GameReadyToStartValue {
	player_count: BigNumberish;
}

// Type definition for `pojo::systems::table::table_systems::GameStarted` struct
export interface GameStarted {
	table_id: BigNumberish;
	game_number: BigNumberish;
	dealer_position: BigNumberish;
	players: Array<string>;
}

// Type definition for `pojo::systems::table::table_systems::GameStartedValue` struct
export interface GameStartedValue {
	dealer_position: BigNumberish;
	players: Array<string>;
}

// Type definition for `pojo::systems::table::table_systems::PlayerJoinedTable` struct
export interface PlayerJoinedTable {
	table_id: BigNumberish;
	player: string;
	position: BigNumberish;
	buy_in: BigNumberish;
}

// Type definition for `pojo::systems::table::table_systems::PlayerJoinedTableValue` struct
export interface PlayerJoinedTableValue {
	position: BigNumberish;
	buy_in: BigNumberish;
}

// Type definition for `pojo::systems::table::table_systems::PlayerLeaveTable` struct
export interface PlayerLeaveTable {
	table_id: BigNumberish;
	player: string;
}

// Type definition for `pojo::systems::table::table_systems::PlayerLeaveTableValue` struct
export interface PlayerLeaveTableValue {
	player: string;
}

// Type definition for `pojo::systems::table::table_systems::TableCreated` struct
export interface TableCreated {
	table_id: BigNumberish;
	creator: string;
	small_blind: BigNumberish;
	big_blind: BigNumberish;
	max_players: BigNumberish;
}

// Type definition for `pojo::systems::table::table_systems::TableCreatedValue` struct
export interface TableCreatedValue {
	creator: string;
	small_blind: BigNumberish;
	big_blind: BigNumberish;
	max_players: BigNumberish;
}

export interface SchemaType extends ISchemaType {
	pojo: {
		Player: Player,
		PlayerValue: PlayerValue,
		CommunityCards: CommunityCards,
		CommunityCardsValue: CommunityCardsValue,
		GameDeck: GameDeck,
		GameDeckValue: GameDeckValue,
		SidePot: SidePot,
		SidePotValue: SidePotValue,
		Table: Table,
		TableCount: TableCount,
		TableCountValue: TableCountValue,
		TablePlayers: TablePlayers,
		TablePlayersValue: TablePlayersValue,
		TableValue: TableValue,
		BettingRoundComplete: BettingRoundComplete,
		BettingRoundCompleteValue: BettingRoundCompleteValue,
		BlindsPosted: BlindsPosted,
		BlindsPostedValue: BlindsPostedValue,
		CommunityCardsDealt: CommunityCardsDealt,
		CommunityCardsDealtValue: CommunityCardsDealtValue,
		HoleCardsDealt: HoleCardsDealt,
		HoleCardsDealtValue: HoleCardsDealtValue,
		PlayerActed: PlayerActed,
		PlayerActedValue: PlayerActedValue,
		PotDistributed: PotDistributed,
		PotDistributedValue: PotDistributedValue,
		GameReadyToStart: GameReadyToStart,
		GameReadyToStartValue: GameReadyToStartValue,
		GameStarted: GameStarted,
		GameStartedValue: GameStartedValue,
		PlayerJoinedTable: PlayerJoinedTable,
		PlayerJoinedTableValue: PlayerJoinedTableValue,
		PlayerLeaveTable: PlayerLeaveTable,
		PlayerLeaveTableValue: PlayerLeaveTableValue,
		TableCreated: TableCreated,
		TableCreatedValue: TableCreatedValue,
	},
}
export const schema: SchemaType = {
	pojo: {
		Player: {
			address: "",
			table_id: 0,
			stack: 0,
			current_bet: 0,
			hole_card1: 0,
			hole_card2: 0,
			is_active: false,
			has_acted: false,
			position: 0,
			last_action: 0,
		},
		PlayerValue: {
			stack: 0,
			current_bet: 0,
			hole_card1: 0,
			hole_card2: 0,
			is_active: false,
			has_acted: false,
			position: 0,
			last_action: 0,
		},
		CommunityCards: {
			table_id: 0,
			game_number: 0,
			flop1: 0,
			flop2: 0,
			flop3: 0,
			turn: 0,
			river: 0,
			cards_dealt: 0,
		},
		CommunityCardsValue: {
			flop1: 0,
			flop2: 0,
			flop3: 0,
			turn: 0,
			river: 0,
			cards_dealt: 0,
		},
		GameDeck: {
			table_id: 0,
			game_number: 0,
			cards: [0],
			next_card_index: 0,
			seed: 0,
		},
		GameDeckValue: {
			cards: [0],
			next_card_index: 0,
			seed: 0,
		},
		SidePot: {
			table_id: 0,
			game_number: 0,
			pot_id: 0,
			amount: 0,
			eligible_players: [""],
		},
		SidePotValue: {
			amount: 0,
			eligible_players: [""],
		},
		Table: {
			table_id: 0,
			creator: "",
			dealer_position: 0,
			small_blind: 0,
			big_blind: 0,
			min_buy_in: 0,
			max_buy_in: 0,
			max_players: 0,
			current_players: 0,
			status: 0,
			current_round: 0,
			pot_total: 0,
			current_bet: 0,
			current_player_position: 0,
			last_raise_amount: 0,
			players_acted_this_round: 0,
			game_number: 0,
		},
		TableCount: {
			id: 0,
			count: 0,
		},
		TableCountValue: {
			count: 0,
		},
		TablePlayers: {
			table_id: 0,
			players: [""],
			player_count: 0,
		},
		TablePlayersValue: {
			players: [""],
			player_count: 0,
		},
		TableValue: {
			creator: "",
			dealer_position: 0,
			small_blind: 0,
			big_blind: 0,
			min_buy_in: 0,
			max_buy_in: 0,
			max_players: 0,
			current_players: 0,
			status: 0,
			current_round: 0,
			pot_total: 0,
			current_bet: 0,
			current_player_position: 0,
			last_raise_amount: 0,
			players_acted_this_round: 0,
			game_number: 0,
		},
		BettingRoundComplete: {
			table_id: 0,
			round: 0,
			pot_total: 0,
		},
		BettingRoundCompleteValue: {
			round: 0,
			pot_total: 0,
		},
		BlindsPosted: {
			table_id: 0,
			small_blind_player: "",
			big_blind_player: "",
			small_blind_amount: 0,
			big_blind_amount: 0,
		},
		BlindsPostedValue: {
			small_blind_player: "",
			big_blind_player: "",
			small_blind_amount: 0,
			big_blind_amount: 0,
		},
		CommunityCardsDealt: {
			table_id: 0,
			game_number: 0,
			round: 0,
			cards_dealt: 0,
		},
		CommunityCardsDealtValue: {
			round: 0,
			cards_dealt: 0,
		},
		HoleCardsDealt: {
			table_id: 0,
			game_number: 0,
			player_count: 0,
		},
		HoleCardsDealtValue: {
			player_count: 0,
		},
		PlayerActed: {
			table_id: 0,
			player: "",
			action: 0,
			amount: 0,
			pot_total: 0,
		},
		PlayerActedValue: {
			action: 0,
			amount: 0,
			pot_total: 0,
		},
		PotDistributed: {
			table_id: 0,
			winner: "",
			amount: 0,
			hand_rank: 0,
		},
		PotDistributedValue: {
			amount: 0,
			hand_rank: 0,
		},
		GameReadyToStart: {
			table_id: 0,
			player_count: 0,
		},
		GameReadyToStartValue: {
			player_count: 0,
		},
		GameStarted: {
			table_id: 0,
			game_number: 0,
			dealer_position: 0,
			players: [""],
		},
		GameStartedValue: {
			dealer_position: 0,
			players: [""],
		},
		PlayerJoinedTable: {
			table_id: 0,
			player: "",
			position: 0,
			buy_in: 0,
		},
		PlayerJoinedTableValue: {
			position: 0,
			buy_in: 0,
		},
		PlayerLeaveTable: {
			table_id: 0,
			player: "",
		},
		PlayerLeaveTableValue: {
			player: "",
		},
		TableCreated: {
			table_id: 0,
			creator: "",
			small_blind: 0,
			big_blind: 0,
			max_players: 0,
		},
		TableCreatedValue: {
			creator: "",
			small_blind: 0,
			big_blind: 0,
			max_players: 0,
		},
	},
};
export enum ModelsMapping {
	Player = 'pojo-Player',
	PlayerValue = 'pojo-PlayerValue',
	CommunityCards = 'pojo-CommunityCards',
	CommunityCardsValue = 'pojo-CommunityCardsValue',
	GameDeck = 'pojo-GameDeck',
	GameDeckValue = 'pojo-GameDeckValue',
	SidePot = 'pojo-SidePot',
	SidePotValue = 'pojo-SidePotValue',
	Table = 'pojo-Table',
	TableCount = 'pojo-TableCount',
	TableCountValue = 'pojo-TableCountValue',
	TablePlayers = 'pojo-TablePlayers',
	TablePlayersValue = 'pojo-TablePlayersValue',
	TableValue = 'pojo-TableValue',
	BettingRoundComplete = 'pojo-BettingRoundComplete',
	BettingRoundCompleteValue = 'pojo-BettingRoundCompleteValue',
	BlindsPosted = 'pojo-BlindsPosted',
	BlindsPostedValue = 'pojo-BlindsPostedValue',
	CommunityCardsDealt = 'pojo-CommunityCardsDealt',
	CommunityCardsDealtValue = 'pojo-CommunityCardsDealtValue',
	HoleCardsDealt = 'pojo-HoleCardsDealt',
	HoleCardsDealtValue = 'pojo-HoleCardsDealtValue',
	PlayerActed = 'pojo-PlayerActed',
	PlayerActedValue = 'pojo-PlayerActedValue',
	PotDistributed = 'pojo-PotDistributed',
	PotDistributedValue = 'pojo-PotDistributedValue',
	GameReadyToStart = 'pojo-GameReadyToStart',
	GameReadyToStartValue = 'pojo-GameReadyToStartValue',
	GameStarted = 'pojo-GameStarted',
	GameStartedValue = 'pojo-GameStartedValue',
	PlayerJoinedTable = 'pojo-PlayerJoinedTable',
	PlayerJoinedTableValue = 'pojo-PlayerJoinedTableValue',
	PlayerLeaveTable = 'pojo-PlayerLeaveTable',
	PlayerLeaveTableValue = 'pojo-PlayerLeaveTableValue',
	TableCreated = 'pojo-TableCreated',
	TableCreatedValue = 'pojo-TableCreatedValue',
}