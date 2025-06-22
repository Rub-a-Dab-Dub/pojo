export enum DashboardMode {
  HOME = 'home',
  PLAY = 'play',
  GAME_LOBBY = 'game_lobby',
  ACTIVE_GAME = 'active_game',
}

export interface Game {
  id: string;
  name: string;
  buyIn: number;
  players: number;
  time: string;
  isCompleted?: boolean;
}

export interface DashboardState {
  mode: DashboardMode;
  selectedGame?: Game;
}

export interface HeroConfig {
  title: string;
  buttonText?: string;
  dealerImage: string;
  dealerPosition: 'left' | 'right';
  chipsImage: string;
  chipsPosition: 'bottom-left' | 'bottom-right';
  textAlignment?: 'left' | 'center' | 'right';
  allowFloatingElements?: boolean;
} 