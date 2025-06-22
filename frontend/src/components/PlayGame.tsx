
import { type Game } from '../types/dashboard';
import { useState } from 'react';

interface PlayGameProps {
  game?: Game;
  onBack: () => void;
  onStartGame: () => void;
}

// Mock player avatars data - enough for proper pagination testing
const playerAvatars = [
  { id: 1, name: 'Alex "The Shark"', avatar: '/src/assets/heroImage.png', isBot: true },
  { id: 2, name: 'Sarah "Ace"', avatar: '/src/assets/playHeroImage.png', isBot: false },
  { id: 3, name: 'Bot Charlie', avatar: '/src/assets/heroImage.png', isBot: true },
  { id: 4, name: 'Mike "Bluff"', avatar: '/src/assets/playHeroImage.png', isBot: false },
  { id: 5, name: 'Bot Diana', avatar: '/src/assets/heroImage.png', isBot: true },
  { id: 6, name: 'Tom "All-in"', avatar: '/src/assets/playHeroImage.png', isBot: false },
  { id: 7, name: 'Bot Elena', avatar: '/src/assets/heroImage.png', isBot: true },
  { id: 8, name: 'Jake "Poker Face"', avatar: '/src/assets/playHeroImage.png', isBot: false },
  { id: 9, name: 'Bot Felix', avatar: '/src/assets/heroImage.png', isBot: true },
  { id: 10, name: 'Lisa "Lucky"', avatar: '/src/assets/playHeroImage.png', isBot: false },
  { id: 11, name: 'Bot Grace', avatar: '/src/assets/heroImage.png', isBot: true },
  { id: 12, name: 'Ryan "River"', avatar: '/src/assets/playHeroImage.png', isBot: false },
  { id: 13, name: 'Bot Henry', avatar: '/src/assets/heroImage.png', isBot: true },
  { id: 14, name: 'Emma "Flush"', avatar: '/src/assets/playHeroImage.png', isBot: false },
  { id: 15, name: 'Bot Ivan', avatar: '/src/assets/heroImage.png', isBot: true },
  { id: 16, name: 'Noah "Nuts"', avatar: '/src/assets/playHeroImage.png', isBot: false },
  { id: 17, name: 'Bot Julia', avatar: '/src/assets/heroImage.png', isBot: true },
  { id: 18, name: 'Zoe "Straight"', avatar: '/src/assets/playHeroImage.png', isBot: false },
  { id: 19, name: 'Bot Kevin', avatar: '/src/assets/heroImage.png', isBot: true },
  { id: 20, name: 'Maya "Check"', avatar: '/src/assets/playHeroImage.png', isBot: false },
  { id: 21, name: 'Bot Liam', avatar: '/src/assets/heroImage.png', isBot: true },
  { id: 22, name: 'Ava "Raise"', avatar: '/src/assets/playHeroImage.png', isBot: false },
  { id: 23, name: 'Bot Mason', avatar: '/src/assets/heroImage.png', isBot: true },
  { id: 24, name: 'Olivia "Fold"', avatar: '/src/assets/playHeroImage.png', isBot: false },
  { id: 25, name: 'Bot Nathan', avatar: '/src/assets/heroImage.png', isBot: true },
  { id: 26, name: 'Sophia "Call"', avatar: '/src/assets/playHeroImage.png', isBot: false },
  { id: 27, name: 'Bot Oscar', avatar: '/src/assets/heroImage.png', isBot: true },
  { id: 28, name: 'Mia "Bet"', avatar: '/src/assets/playHeroImage.png', isBot: false },
  { id: 29, name: 'Bot Paul', avatar: '/src/assets/heroImage.png', isBot: true },
  { id: 30, name: 'Chloe "Royal"', avatar: '/src/assets/playHeroImage.png', isBot: false },
  { id: 31, name: 'Bot Quinn', avatar: '/src/assets/heroImage.png', isBot: true },
  { id: 32, name: 'Ella "Full House"', avatar: '/src/assets/playHeroImage.png', isBot: false },
  { id: 33, name: 'Bot Riley', avatar: '/src/assets/heroImage.png', isBot: true },
  { id: 34, name: 'Grace "High Card"', avatar: '/src/assets/playHeroImage.png', isBot: false },
  { id: 35, name: 'Bot Sam', avatar: '/src/assets/heroImage.png', isBot: true },
  { id: 36, name: 'Luna "Pair"', avatar: '/src/assets/playHeroImage.png', isBot: false },
  { id: 37, name: 'Bot Tyler', avatar: '/src/assets/heroImage.png', isBot: true },
  { id: 38, name: 'Aria "Three Kind"', avatar: '/src/assets/playHeroImage.png', isBot: false },
  { id: 39, name: 'Bot Victor', avatar: '/src/assets/heroImage.png', isBot: true },
  { id: 40, name: 'Hazel "Two Pair"', avatar: '/src/assets/playHeroImage.png', isBot: false },
];

export function PlayGame({ onStartGame }: PlayGameProps) {
  const [selectedPlayers, setSelectedPlayers] = useState<number[]>([]);
  const [currentPage, setCurrentPage] = useState(0);
  
  // Pagination logic
  const playersPerPage = 8;
  const totalPages = Math.ceil(playerAvatars.length / playersPerPage);
  const startIndex = currentPage * playersPerPage;
  const visiblePlayers = playerAvatars.slice(startIndex, startIndex + playersPerPage);

  const handlePlayerSelect = (playerId: number) => {
    setSelectedPlayers(prev => 
      prev.includes(playerId) 
        ? prev.filter(id => id !== playerId)
        : [...prev, playerId]
    );
  };

  const goToPage = (pageIndex: number) => {
    setCurrentPage(pageIndex);
  };

  return (
    <div className="space-y-8">
      {/* Start a Game With Section */}
      <div className="space-y-6">
        <h2 className="text-[16px] font-[600] text-g[#343335]">
          Start a Game With
        </h2>
        
        {/* Player Avatar Carousel */}
        <div className="relative">
          <div className="flex space-x-14 overflow-x-scroll pb-4 [&::-webkit-scrollbar]:hidden [-ms-overflow-style:none] [scrollbar-width:none] scroll-smooth">
            {visiblePlayers.map((player) => {
              const isSelected = selectedPlayers.includes(player.id);
              return (
                <div
                  key={player.id}
                  className="flex-shrink-0 w-24 h-24 cursor-pointer group"
                  onClick={() => handlePlayerSelect(player.id)}
                >
                  <div className="relative w-full h-full">
                    {/* Avatar Circle */}
                    <div className={`w-full h-full rounded-full overflow-hidden border-4 transition-all group-hover:scale-105 transform ${
                      isSelected 
                        ? 'border-[#019EB2] ring-2 ring-[#019EB2] ring-opacity-30' 
                        : 'border-gray-200 hover:border-[#019EB2]'
                    }`}>
                      {player.isBot ? (
                        // Bot placeholder with icon
                        <div className="w-full h-full bg-gradient-to-br from-[#019EB2] to-[#017A8A] flex items-center justify-center">
                          <svg 
                            className="w-8 h-8 text-white" 
                            fill="currentColor" 
                            viewBox="0 0 24 24"
                          >
                            <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/>
                          </svg>
                        </div>
                      ) : (
                        // Real player image
                        <img 
                          src={player.avatar} 
                          alt={player.name}
                          className="w-full h-full object-cover"
                        />
                      )}
                    </div>
                    
                    {/* Selection indicator */}
                    <div className={`absolute -bottom-1 -right-1 w-6 h-6 bg-[#019EB2] rounded-full border-2 border-white transition-opacity ${
                      isSelected ? 'opacity-100' : 'opacity-0 group-hover:opacity-100'
                    }`}>
                      <svg 
                        className="w-3 h-3 text-white absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2" 
                        fill="currentColor" 
                        viewBox="0 0 24 24"
                      >
                        <path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/>
                      </svg>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
          
          {/* Dynamic Pagination Dots */}
          {totalPages > 1 && (
            <div className="flex justify-center space-x-2 mt-4">
              {Array.from({ length: totalPages }, (_, index) => (
                <div
                  key={index}
                  onClick={() => goToPage(index)}
                  className="w-3 h-3 rounded-full cursor-pointer transition-all duration-200 hover:scale-105"
                  style={{
                    backgroundColor: currentPage === index ? '#019EB2' : '#019EB2',
                    opacity: currentPage === index ? 1 : 0.4
                  }}
                  role="button"
                  tabIndex={0}
                  aria-label={`Go to page ${index + 1}`}
                />
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Game Configuration Card */}
      <div className="bg-gradient-to-br from-[#B8E6EA] to-[#A0D9DD] rounded-[30px] border-[#019EB2] p-16 mx-18">
        <div className="space-y-6">
          {/* First Row - Two Full Width Dropdowns */}
          <div className="space-y-4">
            <select className="w-full p-4 rounded-xl border border-gray-200 bg-white/80 backdrop-blur-sm text-gray-700 focus:outline-none focus:ring-2 focus:ring-[#019EB2] focus:border-transparent">
              <option>Select Game Type</option>
              <option>Texas Hold'em</option>
              <option>Omaha</option>
              <option>Seven Card Stud</option>
            </select>
            
            <select className="w-full p-4 rounded-xl border border-gray-200 bg-white/80 backdrop-blur-sm text-gray-700 focus:outline-none focus:ring-2 focus:ring-[#019EB2] focus:border-transparent">
              <option>Select Game Type</option>
              <option>Cash Game</option>
              <option>Tournament</option>
              <option>Sit & Go</option>
            </select>
          </div>

          {/* Second Row - Two Dropdowns Side by Side */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <select className="w-full p-4 rounded-xl border border-gray-200 bg-white/80 backdrop-blur-sm text-gray-700 focus:outline-none focus:ring-2 focus:ring-[#019EB2] focus:border-transparent">
              <option>Select Game Type</option>
              <option>No Limit</option>
              <option>Pot Limit</option>
              <option>Fixed Limit</option>
            </select>
            
            <select className="w-full p-4 rounded-xl border border-gray-200 bg-white/80 backdrop-blur-sm text-gray-700 focus:outline-none focus:ring-2 focus:ring-[#019EB2] focus:border-transparent">
              <option>Select Game Type</option>
              <option>Beginner</option>
              <option>Intermediate</option>
              <option>Advanced</option>
            </select>
          </div>

          {/* Third Row - Set Limit and Start Game Button */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 items-end">
            <select className="w-full p-4 rounded-xl border border-gray-200 bg-white/80 backdrop-blur-sm text-gray-700 focus:outline-none focus:ring-2 focus:ring-[#019EB2] focus:border-transparent">
              <option>Set Limit</option>
              <option>$1/$2</option>
              <option>$2/$5</option>
              <option>$5/$10</option>
              <option>$10/$25</option>
            </select>
            
            <div 
              className="w-full text-white font-semibold py-2 px-8 rounded-[24px] text-lg cursor-pointer text-center select-none"
              style={{ 
                backgroundColor: '#019EB2',
                border: 'none',
                outline: 'none',
                opacity: selectedPlayers.length === 0 ? 0.5 : 1,
                pointerEvents: selectedPlayers.length === 0 ? 'none' : 'auto'
              }}
              onClick={selectedPlayers.length > 0 ? onStartGame : undefined}
            >
              Start Game
            </div>
          </div>
        </div>
      </div>
    </div>
  );
} 