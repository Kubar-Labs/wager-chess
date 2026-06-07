import Link from "next/link";
import { ConnectWallet } from "../components/ConnectWallet";
import { ChessGame } from "../components/ChessGame";

export default function Play() {
  return (
    <div className="flex min-h-screen flex-col bg-background">
      <header className="sticky top-0 z-50 border-b border-border bg-background/80 backdrop-blur-md">
        <div className="mx-auto flex h-16 max-w-7xl items-center justify-between px-4 sm:px-6 lg:px-8">
          <Link href="/" className="flex items-center gap-3 hover:opacity-80 transition-opacity">
            <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-accent">
              <svg viewBox="0 0 24 24" fill="none" className="h-5 w-5 text-white" stroke="currentColor" strokeWidth="2">
                <path d="M10 19l-7-7m0 0l7-7m-7 7h18" />
              </svg>
            </div>
            <h1 className="text-xl font-bold text-foreground">Back to Hub</h1>
          </Link>
          <ConnectWallet />
        </div>
      </header>

      <main className="flex-1">
        <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
          <div className="mx-auto max-w-3xl">
            <ChessGame />
          </div>
        </div>
      </main>
    </div>
  );
}
