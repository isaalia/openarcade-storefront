import type { Metadata } from "next";
import { Syne, DM_Sans } from "next/font/google";
import Link from "next/link";
import "./globals.css";

const syne = Syne({
  variable: "--font-syne",
  subsets: ["latin"],
});

const dmSans = DM_Sans({
  variable: "--font-dm-sans",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "OpenArcade - Indie Game Store",
  description: "Digital game distribution for indie developers",
};

const NAV_ITEMS = [
  { href: "/explore", label: "Explore" },
  { href: "/store", label: "Store" },
  { href: "/library", label: "Library" },
  { href: "/wallet", label: "Wallet" },
];

const FOOTER_LINKS = [
  { href: "/explore", label: "Explore" },
  { href: "/store", label: "Store" },
  { href: "/search", label: "Search" },
  { href: "/library", label: "Library" },
  { href: "/wallet", label: "Wallet" },
];

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className={`${syne.variable} ${dmSans.variable}`}>
      <body className="flex min-h-screen flex-col bg-[#0a0a0b] font-sans text-zinc-100 antialiased">
        <a href="#main" className="skip-link">
          Skip to content
        </a>
        <header className="sticky top-0 z-50 border-b border-zinc-800/60 bg-[#0a0a0b]/70 backdrop-blur-2xl">
          <nav className="mx-auto flex max-w-7xl items-center justify-between px-6 py-4" aria-label="Main">
            <Link
              href="/"
              className="font-display text-xl font-bold tracking-tight text-amber-400 transition-colors hover:text-amber-300 focus-visible:rounded focus-visible:ring-2 focus-visible:ring-amber-400 focus-visible:ring-offset-2 focus-visible:ring-offset-[#0a0a0b] focus-visible:outline-none"
            >
              OpenArcade
            </Link>
            <div className="flex items-center gap-8" role="list">
              {NAV_ITEMS.map((item) => (
                <Link
                  key={item.href}
                  href={item.href}
                  className="text-sm font-medium text-zinc-400 transition-colors hover:text-amber-400"
                >
                  {item.label}
                </Link>
              ))}
              <Link
                href="/profile"
                className="rounded-xl border border-zinc-700/60 px-4 py-1.5 text-sm font-semibold text-zinc-300 transition-colors hover:border-amber-500/60 hover:text-amber-400"
              >
                Account
              </Link>
            </div>
          </nav>
        </header>
        <div className="flex flex-1 flex-col" id="main">
          {children}
        </div>
        <footer className="border-t border-zinc-800/60 bg-zinc-950/50 px-6 py-12">
          <div className="mx-auto flex max-w-7xl flex-col items-center justify-between gap-6 sm:flex-row">
            <span className="font-display text-sm font-semibold text-amber-400">OpenArcade</span>
            <nav className="flex gap-8" aria-label="Footer">
              {FOOTER_LINKS.map((item) => (
                <Link
                  key={item.href}
                  href={item.href}
                  className="text-sm text-zinc-500 transition-colors hover:text-amber-400 focus-visible:text-amber-400"
                >
                  {item.label}
                </Link>
              ))}
            </nav>
            <span className="text-sm text-zinc-600">
              &copy; 2026 Indie games, your way.
            </span>
          </div>
        </footer>
      </body>
    </html>
  );
}
