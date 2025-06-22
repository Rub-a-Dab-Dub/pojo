import { Button } from './ui/button';
import { DashboardMode } from '../types/dashboard';
import { heroConfigs } from '../config/heroConfig';

interface HeroSectionProps {
  mode: DashboardMode;
  onAction: (mode: DashboardMode, data?: any) => void;
}

export function HeroSection({ mode, onAction }: HeroSectionProps) {
  const config = heroConfigs[mode];
  
  const handleButtonClick = () => {
    switch (mode) {
      case DashboardMode.HOME:
        onAction(DashboardMode.PLAY);
        break;
      case DashboardMode.PLAY:
        onAction(DashboardMode.GAME_LOBBY);
        break;
      case DashboardMode.GAME_LOBBY:
        onAction(DashboardMode.HOME);
        break;
      default:
        onAction(DashboardMode.HOME);
    }
  };

  // Clean grid configuration that maintains original visual layout
  const getGridConfig = () => {
    if (config.dealerPosition === 'right') {
      return {
        gridTemplateColumns: '2fr 1fr',
        contentArea: 'content',
        dealerArea: 'dealer'
      };
    } else {
      return {
        gridTemplateColumns: '1fr 2fr', 
        contentArea: 'dealer',
        dealerArea: 'content'
      };
    }
  };

  const getTextAlignment = () => {
    if (config.textAlignment) return config.textAlignment;
    return config.dealerPosition === 'right' ? 'left' : 'right';
  };

  const getContentJustification = () => {
    // Always center the content in the content area
    // Text alignment will be handled within the content container
    return 'center';
  };

  const gridConfig = getGridConfig();
  
  // Use config to determine if floating elements should be allowed
  const shouldAllowOverflow = config.allowFloatingElements || false;

  return (
    <div className={`relative mt-6 mb-8 rounded-2xl bg-[#019EB2] text-white ${!shouldAllowOverflow ? 'overflow-hidden' : ''}`}>
      <div className="absolute inset-0 bg-black/10 rounded-2xl"></div>
      
      {/* CSS Grid Container - maintains original visual layout */}
      <div 
        className={`relative grid h-full min-h-[250px] md:min-h-[300px] ${shouldAllowOverflow ? 'overflow-visible' : ''}`}
        style={{
          gridTemplateColumns: gridConfig.gridTemplateColumns,
          gridTemplateRows: '1fr'
        }}
      >
        {/* Content Area */}
        <div 
          className={`relative flex flex-col justify-center z-10 ${
            mode === DashboardMode.ACTIVE_GAME ? 'md:ml-[-254px] p-4' : 'p-8 md:p-12'
          }`}
          style={{ 
            gridColumn: config.dealerPosition === 'right' ? '1' : '2',
            alignItems: getContentJustification()
          }}
        >
          <div className="max-w-xl">
            <h1 
              className="text-4xl md:text-6xl font-bold mb-6 tracking-wide leading-tight whitespace-nowrap"
              style={{ textAlign: config.textAlignment || 'center' }}
            >
              {config.title}
            </h1>
            {config.buttonText && (
              <div className="flex justify-end">
                <Button 
                  onClick={handleButtonClick} 
                  size="lg" 
                  className="bg-white text-[#019EB2] hover:bg-gray-100 font-semibold px-8 py-3 rounded-full"
                >
                  {config.buttonText}
                </Button>
              </div>
            )}
          </div>
        </div>

        {/* Dealer Area - Conditional overflow for floating elements */}
        <div 
          className={`relative hidden md:block z-20 ${shouldAllowOverflow ? 'overflow-visible' : ''}`}
          style={{ 
            gridColumn: config.dealerPosition === 'right' ? '2' : '1',
            gridRow: '1'
          }}
        >
          <img 
            src={config.dealerImage} 
            alt="Poker dealer" 
            className="w-full h-full object-cover"
            style={shouldAllowOverflow ? {
              transform: 'scale(1.1) translateY(-10%)',
              transformOrigin: 'center'
            } : {}}
          />
        </div>
      </div>

      {/* Chips - Absolute positioned like before but cleaner logic */}
      <div 
        className={`absolute bottom-0 hidden md:block z-30 ${
          config.chipsPosition === 'bottom-left' ? 'left-0' : 'right-0'
        }`}
      >
        <img 
          src={config.chipsImage} 
          alt="Casino chips" 
          className="w-auto h-16 md:h-20 object-contain" 
        />
      </div>
    </div>
  );
} 