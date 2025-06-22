"use client"

import { Search, Bell, ChevronDown, Menu } from "lucide-react"
import { Button } from "./ui/button"
import { Input } from "./ui/input"
import { Avatar, AvatarFallback, AvatarImage } from "./ui/avatar"
import { SidebarTrigger } from "./ui/sidebar"
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "./ui/dropdown-menu"
import collapsible from "../assets/collapsible.svg"

export function Header() {
  return (
    <header className="px-4 flex h-[59px] w-full items-center justify-between border-b border-l-0 border-[#E5E5E5] bg-white -ml-px">
      <div className="flex items-center gap-4">
        <SidebarTrigger className="hover:bg-gray-100 rounded-full border border-#E5E5E5">
          <img src={collapsible} className="w-5 h-5" />
        </SidebarTrigger>

        <div className="relative">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4 "/>
          <Input placeholder="Search" className="pl-10 w-[378px] bg-white border-gray-[#E5E5E5] rounded-[30px]" />
        </div>
      </div>

      <div className="flex items-center gap-4">
        <Button variant="ghost" size="icon" className="relative">
          <Bell className="w-5 h-5" />
          <span className="absolute -top-1 -right-1 w-3 h-3 bg-red-500 rounded-full text-xs"></span>
        </Button>

        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button variant="ghost" className="flex items-center gap-2 px-3">
              <Avatar className="w-8 h-8 ">
                <AvatarImage src="/placeholder.svg?height=32&width=32" />
                <AvatarFallback className="bg-orange-500 text-white">DO</AvatarFallback>
              </Avatar>
              <span className="font-medium text-[#343335]">Daniel Odinegun</span>
              <ChevronDown className="w-4 h-4" />
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end">
            <DropdownMenuItem>Profile</DropdownMenuItem>
            <DropdownMenuItem>Settings</DropdownMenuItem>
            <DropdownMenuItem>Sign out</DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </div>
    </header>
  )
}
