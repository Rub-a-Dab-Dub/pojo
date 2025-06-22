import type { LucideProps } from "lucide-react"
import React from "react"
import {
  Sidebar,
  SidebarContent,
  SidebarGroup,
  SidebarGroupContent,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
} from "./ui/sidebar"
import pojoLogo from '../assets/PojoLogo.png'
import HomeIcon  from "../assets/HomeIcon.svg"
import tableIconExpanded from '../assets/TableIconExpanded.png'
import tableIconCollapsed from '../assets/TableIconCollapesd.png'

type NavItem = {
  title: string
  url: string
  isActive: boolean
} & ({
  isLucide: true
  icon: React.ForwardRefExoticComponent<Omit<LucideProps, "ref"> & React.RefAttributes<SVGSVGElement>>
} | {
  isLucide: false
  collapsedIcon: string
  expandedIcon: string
})

const navigationItems: NavItem[] = [
  {
    title: "Home",
    collapsedIcon: HomeIcon,
    expandedIcon: HomeIcon,
    isLucide: false,
    url: "#",
    isActive: false,
  },
  {
    title: "Tables",
    collapsedIcon: tableIconCollapsed,
    expandedIcon: tableIconExpanded,
    isLucide: false,
    url: "#",
    isActive: true,
  },
]

export function AppSidebar() {
  return (
    <Sidebar collapsible="icon" className="border-r border-gray-[#E5E5E5]" >
      <SidebarHeader className="p-4 group-data-[state=collapsed]:p-2">
        <div className="flex items-center group-data-[state=expanded]:gap-2 group-data-[state=expanded]:ml-[30px] group-data-[state=collapsed]:justify-center ml-[5px] ">
          <div className="w-8 h-8 rounded-full flex items-center justify-center">
              <img src={pojoLogo} alt="POJO Poker Logo" />
            </div>
          <span className="font-bold text-lg text-[#019EB2] group-data-[state=collapsed]:hidden">POJO</span>
        </div>
      </SidebarHeader>
      <SidebarContent>
        <SidebarGroup>
          <SidebarGroupContent>
            <SidebarMenu className="mt-[52px] flex flex-col group-data-[state=expanded]:ml-2 group-data-[state=collapsed]:items-center group-data-[state=collapsed]:gap-y-6 group-data-[state=collapsed]:ml-2 ml-20 ">
              {navigationItems.map((item) => (
                <SidebarMenuItem
                  key={item.title}
                  className="relative group-data-[state=expanded]:ml-[30px]"
                  data-active={item.isActive}
                >
                  <SidebarMenuButton
                    asChild
                    isActive={item.isActive}
                    size={"lg"}
                    className="w-full"
                  >
                    <a href={item.url} className="flex items-center group-data-[state=expanded]:gap-3 group-data-[state=expanded]:py-0 group-data-[state=collapsed]:p-2 group-data-[state=collapsed]:justify-center">
                      {item.isLucide ? (
                        <item.icon className="w-[44px] h-[32px] text-[#71717A]" />
                      ) : (
                        <>
                          <img
                            src={item.expandedIcon}
                            alt={`${item.title} icon`}
                            className="w-[34px] h-[22px] group-data-[state=collapsed]:hidden"
                          />
                          <img
                            src={item.collapsedIcon}
                            alt={`${item.title} icon`}
                            className="group-data-[state=expanded]:hidden group-data-[state=collapsed]:p-2"
                          />
                        </>
                      )}
                      <span className="font-[SF Pro] font-normal text-[17px] leading-[100%] tracking-[1px] text-[#71717A]  text-center group-data-[state=collapsed]:hidden ">
                        {item.title}
                      </span>
                    </a>
                  </SidebarMenuButton>
                </SidebarMenuItem>
              ))}
            </SidebarMenu>
          </SidebarGroupContent>
        </SidebarGroup>
      </SidebarContent>
    </Sidebar>
  )
}
