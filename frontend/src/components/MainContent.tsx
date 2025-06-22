import { DashboardMode, type Game } from '../types/dashboard';
import { GameSection } from './game-section';
import { PlayGame } from './PlayGame';
import { ActiveGame } from './ActiveGame';
import type { GameData } from './game-card';

// Mock data that was previously in GameDashboard
const mockGames: GameData[] = [
  { id: "1", name: "Mac'n Chesse", buyIn: 475, time: "16:00", status: "in-progress", players: 4 },
  { id: "2", name: "Mac'n Chesse", buyIn: 475, time: "16:00", status: "in-progress", players: 4 },
  { id: "3", name: "Mac'n Chesse", buyIn: 475, time: "16:00", status: "in-progress", players: 4 },
  { id: "4", name: "Mac'n Chesse", buyIn: 475, time: "16:00", status: "in-progress", players: 4 },
  { id: "5", name: "Mac'n Chesse", buyIn: 475, time: "16:00", status: "completed", players: 4 },
  { id: "6", name: "Mac'n Chesse", buyIn: 475, time: "16:00", status: "completed", players: 3 },
  { id: "7", name: "Mac'n Chesse", buyIn: 475, time: "16:00", status: "completed", players: 4 },
  { id: "8", name: "Mac'n Chesse", buyIn: 475, time: "16:00", status: "completed", players: 4 },
];

interface MainContentProps {
  mode: DashboardMode;
  onAction: (mode: DashboardMode, data?: any) => void;
  selectedGame?: Game;
}

export function MainContent({ mode, onAction, selectedGame }: MainContentProps) {
  const handleGameSelect = (game: Game) => {
    onAction(DashboardMode.PLAY, { selectedGame: game });
  };

  const handleBackToHome = () => {
    onAction(DashboardMode.HOME);
  };

  const handleStartGame = () => {
    onAction(DashboardMode.ACTIVE_GAME);
  };

  const inProgressGames = mockGames.filter((game) => game.status === "in-progress");
  const completedGames = mockGames.filter((game) => game.status === "completed");

  switch (mode) {
    case DashboardMode.HOME:
      return (
        <>
          <GameSection title="In Progress" games={inProgressGames} onGameSelect={handleGameSelect} />
          <GameSection title="Completed" games={completedGames} onGameSelect={handleGameSelect} />
        </>
      );
    
    case DashboardMode.PLAY:
      return <PlayGame game={selectedGame} onBack={handleBackToHome} onStartGame={handleStartGame} />;
    
    case DashboardMode.GAME_LOBBY:
      return (
        <div className="bg-white rounded-2xl p-12 text-center">
          <h3 className="text-2xl font-bold text-[#019EB2] mb-4">
            Game Lobby
          </h3>
          <p className="text-gray-600 mb-6">
            Waiting for other players to join...
          </p>
          <button 
            onClick={handleBackToHome}
            className="bg-[#019EB2] text-white px-6 py-3 rounded-full hover:bg-[#017a8a] transition-colors"
          >
            Leave Lobby
          </button>
        </div>
      );
    
    case DashboardMode.ACTIVE_GAME:
      return <ActiveGame />;
    
    default:
      return (
        <>
          <GameSection title="In Progress" games={inProgressGames} onGameSelect={handleGameSelect} />
          <GameSection title="Completed" games={completedGames} onGameSelect={handleGameSelect} />
        </>
      );
  }
} 