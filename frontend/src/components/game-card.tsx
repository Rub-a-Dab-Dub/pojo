import { Card, CardContent } from "./ui/card"

export interface GameData {
  id: string
  name: string
  buyIn: number
  time: string
  status: "in-progress" | "completed"
  players: number
}

interface GameCardProps {
  game: GameData
  className?: string
}

export function GameCard({ game, className = "" }: GameCardProps) {
  const isCompleted = game.status === "completed"

  return (
    <Card className={`${className}`}>
      <CardContent className="p-0 rounded-[30px]">
        <div className="flex items-center mb-4">
          <div className="flex items-center ">
            <div
              className={`mx-4 w-6 h-6 rounded-full flex items-center justify-center text-white text-sm font-medium ${
                isCompleted ? "bg-gray-500" : "bg-[#019EB2]"
              }`}
            >
              {game.players}
            </div>
            <div className="flex items-center text-sm text-[#343335]">
              <span>{game.time}</span>
            </div>
          </div>
        </div>

        <div
          className={`rounded-[15px] p-4 text-center h-full mb-[-20px] ${
            isCompleted ? "bg-gray-400 text-white" : "bg-[#019EB266]  text-[#1E666F]"
          }`}
        >
          <h3 className="font-semibold text-[25px] mb-2">{game.name}</h3>
          <p className="text-[50px] font-[600]">${game.buyIn}</p>
        </div>
      </CardContent>
    </Card>
  )
}
