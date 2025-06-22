import { DashboardMode, type HeroConfig } from '../types/dashboard';

export const heroConfigs: Record<DashboardMode, HeroConfig> = {
  [DashboardMode.HOME]: {
    title: "LET'S HAVE SOME FUN",
    buttonText: "LET'S PLAY",
    dealerImage: "/src/assets/heroImage.png",
    dealerPosition: "right" as const,
    chipsImage: "/src/assets/mission_title_2.png",
    chipsPosition: "bottom-left" as const
  },
  [DashboardMode.PLAY]: {
    title: "LET'S PLAY SOME POKER",
    dealerImage: "/src/assets/playHeroImage.png", 
    dealerPosition: "left" as const,
    chipsImage: "/src/assets/mission_title_2.png",
    chipsPosition: "bottom-right" as const,
    textAlignment: "right" as const
  },
  [DashboardMode.GAME_LOBBY]: {
    title: "WAITING FOR PLAYERS...",
    dealerImage: "/src/assets/heroImage.png",
    dealerPosition: "right" as const,
    chipsImage: "/src/assets/mission_title_2.png",
    chipsPosition: "bottom-left" as const
  },
  [DashboardMode.ACTIVE_GAME]: {
    title: "GAME",
    dealerImage: "/src/assets/poker_game.png",
    dealerPosition: "left" as const,
    chipsImage: "/src/assets/mission_title_2.png",
    chipsPosition: "bottom-right" as const,
    textAlignment: "center" as const,
    allowFloatingElements: true
  }
}; 