"use client"

import { Menu } from "lucide-react"
import { Button } from "@/components/ui/button"
import { SheetTrigger } from "@/components/ui/sheet"

export function MenuButton() {
    return (
        <SheetTrigger asChild>
            <Button variant="ghost" size="icon" className="mr-2">
                <Menu className="w-5 h-5" />
            </Button>
        </SheetTrigger>
    )
}
