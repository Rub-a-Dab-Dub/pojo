import { GameCard, type GameData } from "./game-card"
import { type Game } from "../types/dashboard"

interface GameSectionProps {
  title?: string
  games?: GameData[]
  className?: string
  onGameSelect?: (game: Game) => void
}

// Mock data for games if none provided
const mockGames: GameData[] = [
  { id: "1", name: "Texas Hold'em", buyIn: 50, players: 8, time: "15 min", status: "in-progress" },
  { id: "2", name: "Omaha", buyIn: 100, players: 6, time: "30 min", status: "in-progress" },
  { id: "3", name: "Seven Card Stud", buyIn: 25, players: 7, time: "20 min", status: "in-progress" },
  { id: "4", name: "Razz", buyIn: 75, players: 5, time: "25 min", status: "completed" },
]

export function GameSection({ 
  title = "Available Games", 
  games = mockGames, 
  className = "", 
  onGameSelect 
}: GameSectionProps) {
  
  const handleGameClick = (gameData: GameData) => {
    if (onGameSelect) {
      // Convert GameData to Game format
      const game: Game = {
        id: gameData.id,
        name: gameData.name,
        buyIn: gameData.buyIn,
        players: gameData.players,
        time: gameData.time,
        isCompleted: gameData.status === "completed"
      }
      onGameSelect(game)
    }
  }

  return (
    <section className={`mb-8 ${className}`}>
      <h2 className="text-xl font-semibold mb-4 text-gray-800">{title}</h2>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {games.map((game) => (
          <div key={game.id} onClick={() => handleGameClick(game)} className="cursor-pointer">
            <GameCard game={game} />
          </div>
        ))}
      </div>

      {games.length > 4 && (
        <div className="flex justify-center mt-6">
          <div className="flex gap-2">
            {Array.from({ length: Math.ceil(games.length / 4) }).map((_, index) => (
              <div key={index} className={`w-2 h-2 rounded-full ${index === 0 ? "bg-teal-500" : "bg-gray-300"}`} />
            ))}
          </div>
        </div>
      )}
    </section>
  )
}
