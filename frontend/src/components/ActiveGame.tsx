import { useState } from 'react';
import chipsIcon from '../assets/chipsIcon.svg'

interface Player {
  id: number;
  name: string;
  avatar: string;
  chips: string;
  position: 'top-left' | 'top-right' | 'middle-left' | 'middle-right' | 'bottom-left' | 'bottom-right';
}

// Mock game data matching the image
const players: Player[] = [
  { id: 1, name: 'Barry', avatar: '/src/assets/playHeroImage.png', chips: '170K', position: 'top-left' },
  { id: 2, name: 'Dianne', avatar: '/src/assets/heroImage.png', chips: '210K', position: 'top-right' },
  { id: 3, name: 'Guy', avatar: '/src/assets/playHeroImage.png', chips: '110K', position: 'middle-left' },
  { id: 4, name: 'Nigel', avatar: '/src/assets/heroImage.png', chips: '200K', position: 'bottom-left' },
  { id: 5, name: 'Girth', avatar: '/src/assets/playHeroImage.png', chips: '180K', position: 'bottom-right' },
];

const communityCards = [
  { suit: 'hearts', value: '6' },
  { suit: 'clubs', value: 'J' },
  { suit: 'hearts', value: '6' },
  { suit: 'spades', value: 'back' },
  { suit: 'spades', value: 'back' },
];

const playerCards = [
  { suit: 'spades', value: 'A' },
  { suit: 'spades', value: 'K' },
];

export function ActiveGame() {
  const [selectedAction, setSelectedAction] = useState<string | null>(null);

  // Calculate elliptical player positions around the 750x477 oval table
  const getPlayerPositionClasses = (position: string) => {
    switch (position) {
      case 'top-left': // Barry - top-left position
        return 'absolute left-[138px] top-[40px] -translate-x-1/2 -translate-y-1/2';
      case 'top-right': // Dianne - top-right position  
        return 'absolute left-[672px] top-[40px] -translate-x-1/2 -translate-y-1/2';
      case 'middle-left': // Guy - left side
        return 'absolute left-[10px] top-[238px] -translate-x-1/2 -translate-y-1/2';
      case 'middle-right': // Right player - right side
        return 'absolute left-[695px] top-[338px] -translate-x-1/2 -translate-y-1/2';
      case 'bottom-left': // Nigel - bottom-left
        return 'absolute left-[78px] top-[488px] -translate-x-1/2 -translate-y-1/2';
      case 'bottom-right': // Girth - bottom-right
        return 'absolute left-[708px] top-[488px] -translate-x-1/2 -translate-y-1/2';
      default: return '';
    }
  };

  const renderCard = (card: { suit: string; value: string }, index: number) => {
    if (card.suit === 'spades' && card.value === 'back') {
      // Card back
      return (
        <div key={index} className="w-12 h-16 bg-blue-800 rounded-lg border-2 border-white flex items-center justify-center">
          <div className="w-8 h-8 bg-blue-600 rounded-full"></div>
        </div>
      );
    }
    
    // Face card
    const suitSymbols = {
      hearts: '♥',
      diamonds: '♦',
      clubs: '♣',
      spades: '♠'
    };
    
    const isRed = card.suit === 'hearts' || card.suit === 'diamonds';
    
    return (
      <div key={index} className="w-12 h-16 bg-white rounded-lg border-2 border-gray-300 flex flex-col items-center justify-between p-1">
        <div className={`text-xs font-bold ${isRed ? 'text-red-500' : 'text-black'}`}>
          {card.value}
        </div>
        <div className={`text-lg ${isRed ? 'text-red-500' : 'text-black'}`}>
          {suitSymbols[card.suit as keyof typeof suitSymbols]}
        </div>
        <div className={`text-xs font-bold rotate-180 ${isRed ? 'text-red-500' : 'text-black'}`}>
          {card.value}
        </div>
      </div>
    );
  };

  return (
    <div className="w-full">
    <div className="relative w-full h-[600px] rounded-3xl overflow-hidden">
      
      {/* Background Decorative Elements */}
      {/* Top-right chip stack decoration */}
      <div className="absolute top-4 right-4 z-10">
        <img 
          src="/src/assets/smiling_face_top.png" 
          alt="Decorative chips" 
          className="w-20 h-20 md:w-24 md:h-24 object-contain opacity-90"
        />
      </div>
      
      {/* Bottom-left chip stack decoration */}
      <div className="absolute bottom-4 left-4 z-10">
        <img 
          src="/src/assets/smiling_face_bottom.png" 
          alt="Decorative chips" 
          className="w-20 h-20 md:w-24 md:h-24 object-contain opacity-90"
        />
      </div>

      {/* Poker Table Surface - Figma Specs: 477px width, 244px border-radius, 5px white border, #EFEFEF bg */}
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[850px] h-[527px] bg-[#EFEFEF] border-[10px] border-white rounded-[244px]">
        
        {/* Players positioned around the table - Higher z-index to appear above inner circle */}
        {players.map((player) => (
          <div key={player.id} className={`${getPlayerPositionClasses(player.position)} z-20`}>
            <div className="flex flex-col items-center space-y-2">
              {/* Player Avatar */}
              <div className="w-16 h-16 rounded-full overflow-hidden border-[2px] border-[#019EB2]">
                <img 
                  src={player.avatar} 
                  alt={player.name}
                  className="w-full h-full object-cover"
                />
              </div>
              {/* Player Name */}
              <div className='bg-white px-6 py-1 flex flex-col item-center justify-between rounded-[6px] shadow hover:shadow-md'>
              <div className="text-[#343335] text-[12px] font-[400] mx-auto">{player.name}</div>
              {/* Player Chips */}
              <div className="p-2 text-[14px] font-[400] flex items-center justify-between gap-2 ">
                <img src={chipsIcon} alt="chips icon" className='w-4 h-4' />
                {player.chips}
              </div>
              </div>
            
            </div>
          </div>
        ))}

        {/* Inner Circle with 5px border - Lower z-index so players appear above */}
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[490px] bg-[#EFEFEF] border-[5px] border-white rounded-full z-10">
          
          {/* Central Pot Area */}
          <div className="absolute top-1/3 left-1/2 -translate-x-1/2 -translate-y-1/2">
            <div className="flex flex-col items-center space-y-4">
              {/* Pot Amount */}
              <div className="text-center">
                <div className="text-gray-600 text-sm mb-1">Bank</div>
                <div className="bg-[#019EB2] text-white px-6 py-4 rounded-full font-[400]">
                  ⊕ 210K
                </div>
              </div>
              
              {/* Community Cards */}
              <div className="flex space-x-2">
                {communityCards.map((card, index) => renderCard(card, index))}
              </div>
              
              {/* Hand Description */}
              <div className="text-center bg-[#E0EEF0] p-4 rounded-[6px] mb-[27px]">
                <div className="text-teal-500 text-xs font-semibold">THREE OF A KIND</div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Player's Cards (Bottom Center) */}
      <div className="absolute bottom-28 left-1/2 -translate-x-1/2">
        <div className="flex flex-col items-center space-y-3">
          {/* Player Cards */}
          <div className="flex space-x-2">
            {playerCards.map((card, index) => renderCard(card, index))}
          </div>
          
          {/* Turn Indicator */}
          <div className="text-center">
          <div className="text-[#888888] text-[12px] font-[400] mb-1">Your Turn</div>
          <div className="text-[#343335] font-[500] text-[16px]">Check or Raise</div>
          </div>
        </div>
      </div>
    </div>

    {/* Action Buttons - Positioned below the table */}
    <div className="flex justify-center mt-8">
      <div className="flex space-x-4 bg-white rounded-full py-1 px-2 shadow-lg">
        <div 
          className="px-8 py-1 hover:bg-gray-300 my-auto text-gray-700 rounded-full font-medium transition-colors"
          onClick={() => setSelectedAction('fold')}
        >
          Fold
        </div>
        <div 
          className="px-8 py-1 bg-[#019EB2] hover:bg-[#017a8a] my-auto text-white rounded-full font-medium transition-colors"
          onClick={() => setSelectedAction('check')}
        >
          Check
        </div>
        <div 
          className="px-8 my-auto py-1 hover:bg-gray-300 text-gray-700 rounded-full font-medium transition-colors"
          onClick={() => setSelectedAction('raise')}
        >
          Raise
        </div>
      </div>
    </div>
    </div>
  );
} 