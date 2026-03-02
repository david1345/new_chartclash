"use client";

import { useEffect, useState } from "react";

/**
 * Custom hook to determine if the component has mounted on the client.
 * Useful for preventing hydration mismatches with locale-sensitive or dynamic content.
 */
export function useMounted() {
    const [mounted, setMounted] = useState(false);

    useEffect(() => {
        setMounted(true);
    }, []);

    return mounted;
}
