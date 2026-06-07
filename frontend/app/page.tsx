import { ConnectWallet } from "./components/ConnectWallet";
import { ChessGame } from "./components/ChessGame";
import { Dashboard } from "./components/Dashboard";

export default function Home() {
  return (
    <div className="flex min-h-screen flex-col bg-background">
      {/* Header */}
      <header className="sticky top-0 z-50 border-b border-border bg-background/80 backdrop-blur-md">
        <div className="mx-auto flex h-16 max-w-7xl items-center justify-between px-4 sm:px-6 lg:px-8">
          <div className="flex items-center gap-3">
            <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-accent">
              <svg
                viewBox="0 0 24 24"
                fill="none"
                className="h-5 w-5 text-white"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <path d="M8 16l-4-4 4-4" />
                <path d="M16 8l4 4-4 4" />
              </svg>
            </div>
            <h1 className="text-xl font-bold text-foreground">Wager Chess</h1>
          </div>
          <ConnectWallet />
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1">
        <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
          <div className="grid grid-cols-1 gap-8 lg:grid-cols-12">
            {/* Chess Board */}
            <div className="lg:col-span-7">
              <div className="mx-auto max-w-[500px] lg:max-w-none">
                <ChessGame />
              </div>
            </div>

            {/* Dashboard */}
            <div className="lg:col-span-5">
              <Dashboard potSize="1.25" personalSpend="0.05" />
            </div>
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="border-t border-border py-6">
        <div className="mx-auto max-w-7xl px-4 text-center text-sm text-zinc-500 sm:px-6 lg:px-8">
          Built on Monad Testnet. Play responsibly.
        </div>
      </footer>
    </div>
  );
}
