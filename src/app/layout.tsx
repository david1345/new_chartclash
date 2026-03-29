export const dynamic = "force-dynamic";
import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";
import { ThemeProvider } from "@/providers/theme-provider";
import { Toaster } from "@/components/ui/sonner";
import { Footer } from "@/components/layout/footer";
import { BottomNav } from "@/components/layout/bottom-nav";
import { GoogleAnalytics } from '@next/third-parties/google';
import { ResolutionProvider } from "@/providers/resolution-provider";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  metadataBase: new URL("https://chartclash.app"),
  title: "ChartClash",
  description: "Predict. Compete. Clash with the Market.",
};

export const viewport = {
  width: "device-width",
  initialScale: 1,
  maximumScale: 1,
  userScalable: false,
};

// --- CLIENT SIDE AUTO-RELOAD ON CHUNK ERROR ---
// This corrects "Loading chunk" errors
// after a new deployment when users are on an old version.
const CACHE_BUSTER_SCRIPT = `
  (function() {
    window.addEventListener('error', function(e) {
      if (e.message && e.message.indexOf('Loading chunk') !== -1) {
        console.warn('Chunk load error detected! Forcing hard reload...');
        // Add a session storage flag to prevent infinite reload loops
        if (!sessionStorage.getItem('chunk_reload_attempted')) {
            sessionStorage.setItem('chunk_reload_attempted', 'true');
            window.location.reload(true);
        }
      }
    }, true);
  })();
`;

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body
        className={`${geistSans.variable} ${geistMono.variable} antialiased`}
      >
        <ThemeProvider
          attribute="class"
          defaultTheme="dark"
          enableSystem={false}
          disableTransitionOnChange
        >
          <ResolutionProvider>
            {children}
            <BottomNav />
            <Footer />
            <Toaster />
          </ResolutionProvider>
        </ThemeProvider>
        {process.env.NEXT_PUBLIC_GA_ID && (
          <GoogleAnalytics gaId={process.env.NEXT_PUBLIC_GA_ID} />
        )}
        <script dangerouslySetInnerHTML={{ __html: CACHE_BUSTER_SCRIPT }} />
      </body>
    </html>
  );
}
