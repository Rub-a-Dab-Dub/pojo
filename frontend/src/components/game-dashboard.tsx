import { useState } from 'react';
import { DashboardMode, type DashboardState } from '../types/dashboard';
import { HeroSection } from './HeroSection';
import { MainContent } from './MainContent';

export function GameDashboard() {
  const [dashboardState, setDashboardState] = useState<DashboardState>({
    mode: DashboardMode.HOME
  });

  const handleModeChange = (mode: DashboardMode, data?: any) => {
    setDashboardState(prev => ({
      ...prev,
      mode,
      ...data
    }));
  };

  return (
    <main className="flex-1 p-6 bg-gradient-to-br from-gray-50 to-gray-100 min-h-screen">
      <HeroSection 
        mode={dashboardState.mode}
        onAction={handleModeChange}
      />
      
      <MainContent 
        mode={dashboardState.mode}
        onAction={handleModeChange}
        selectedGame={dashboardState.selectedGame}
      />
    </main>
  );
}
