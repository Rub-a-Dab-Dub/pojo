
import './App.css'
import { SidebarInset, SidebarProvider } from './components/ui/sidebar'
import { AppSidebar } from './components/app-sidebar'
import { Header } from './components/header'
import { GameDashboard } from './components/game-dashboard'

function App() {

  return (
    <>
      <SidebarProvider defaultOpen={true}>
      <AppSidebar />
      <SidebarInset>
        <Header />
        <GameDashboard />
      </SidebarInset>
    </SidebarProvider>
    </>
  )
}

export default App
