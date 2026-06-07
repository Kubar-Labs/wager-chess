import Link from "next/link";
import { ConnectWallet } from "./components/ConnectWallet";

export default function Home() {
  return (
    <div className="flex min-h-screen flex-col bg-background text-foreground">
      {/* Header */}
      <header className="sticky top-0 z-50 border-b border-border bg-background/80 backdrop-blur-md">
        <div className="mx-auto flex h-16 max-w-7xl items-center justify-between px-4 sm:px-6 lg:px-8">
          <div className="flex items-center gap-3">
            <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-accent">
              <svg viewBox="0 0 24 24" fill="none" className="h-5 w-5 text-white" stroke="currentColor" strokeWidth="2">
                <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5" />
              </svg>
            </div>
            <h1 className="text-xl font-bold tracking-tight">Wager Chess</h1>
          </div>
          <div className="flex items-center gap-4">
            <Link href="/play" className="text-sm font-medium hover:text-accent transition-colors hidden sm:block">Play Now</Link>
            <ConnectWallet />
          </div>
        </div>
      </header>

      <main className="flex-1">
        {/* Hero Section */}
        <section className="relative px-4 py-24 sm:px-6 lg:px-8 text-center overflow-hidden">
          <div className="absolute inset-0 -z-10 bg-[radial-gradient(ellipse_at_top,_var(--tw-gradient-stops))] from-accent/20 via-background to-background"></div>
          <h1 className="text-5xl font-extrabold tracking-tight sm:text-7xl mb-6">
            Pay Per <span className="text-transparent bg-clip-text bg-gradient-to-r from-accent to-blue-500">Move.</span>
          </h1>
          <p className="mx-auto max-w-2xl text-lg text-zinc-400 mb-10">
            A hyper-financialized variant of chess deployed on the Monad testnet. Every move costs real tokens. Winner takes the entire pot.
          </p>
          <div className="flex justify-center gap-4">
            <Link href="/play" className="rounded-lg bg-accent px-8 py-3.5 text-lg font-bold text-white transition-all hover:bg-accent-hover shadow-[0_0_20px_rgba(37,99,235,0.3)] hover:scale-105">
              Start a Game
            </Link>
            <a href="#rules" className="rounded-lg bg-surface-raised border border-border px-8 py-3.5 text-lg font-medium transition-all hover:bg-border">
              Read the Rules
            </a>
          </div>
        </section>

        {/* Rules Section */}
        <section id="rules" className="mx-auto max-w-5xl px-4 py-20 sm:px-6 lg:px-8">
          <div className="rounded-2xl border border-border bg-surface p-8 sm:p-12 shadow-2xl">
            <h2 className="text-3xl font-bold mb-8 text-center">The Rules of Engagement</h2>
            
            <div className="grid gap-12 md:grid-cols-2">
              <div>
                <h3 className="text-xl font-semibold mb-4 flex items-center gap-2">
                  <span className="flex h-8 w-8 items-center justify-center rounded-full bg-accent/20 text-accent">1</span>
                  The Buy-In
                </h3>
                <p className="text-zinc-400 leading-relaxed">
                  Every game requires a base wager (0.01 MON) to create or join. This forms the initial prize pot held securely in the escrow contract.
                </p>
              </div>

              <div>
                <h3 className="text-xl font-semibold mb-4 flex items-center gap-2">
                  <span className="flex h-8 w-8 items-center justify-center rounded-full bg-accent/20 text-accent">2</span>
                  Dynamic Move Fees
                </h3>
                <p className="text-zinc-400 leading-relaxed mb-4">
                  Moving pieces isn't free. The more powerful the piece, the more you pay into the pot:
                </p>
                <ul className="space-y-2 text-sm">
                  <li className="flex justify-between border-b border-border/50 pb-2"><span>♛ Queen</span> <span className="font-mono text-accent">0.0009 MON ($9)</span></li>
                  <li className="flex justify-between border-b border-border/50 pb-2"><span>♜ Rook</span> <span className="font-mono text-zinc-300">0.0005 MON ($5)</span></li>
                  <li className="flex justify-between border-b border-border/50 pb-2"><span>♝ Bishop / ♞ Knight</span> <span className="font-mono text-zinc-300">0.0003 MON ($3)</span></li>
                  <li className="flex justify-between pt-1"><span>♟ Pawn / ♚ King</span> <span className="font-mono text-zinc-500">0.0001 MON ($1)</span></li>
                </ul>
              </div>

              <div>
                <h3 className="text-xl font-semibold mb-4 flex items-center gap-2">
                  <span className="flex h-8 w-8 items-center justify-center rounded-full bg-red-500/20 text-red-400">3</span>
                  The Check Penalty
                </h3>
                <p className="text-zinc-400 leading-relaxed">
                  Aggression is taxed. Putting your opponent in check costs an additional <span className="text-red-400 font-mono">0.0005 MON ($5)</span> on top of the base piece movement fee.
                </p>
              </div>

              <div>
                <h3 className="text-xl font-semibold mb-4 flex items-center gap-2">
                  <span className="flex h-8 w-8 items-center justify-center rounded-full bg-green-500/20 text-green-400">4</span>
                  Winner Takes All
                </h3>
                <p className="text-zinc-400 leading-relaxed">
                  The player who delivers Checkmate immediately claims the entire accumulated pot (base wagers + all move fees paid by both players). A stalemate splits the pot.
                </p>
              </div>
            </div>
          </div>
        </section>
      </main>

      <footer className="border-t border-border py-8 mt-12">
        <div className="mx-auto flex max-w-7xl flex-col md:flex-row items-center justify-between px-4 text-sm text-zinc-500 sm:px-6 lg:px-8">
          <p>Built on the Monad Testnet for high-throughput gaming.</p>
          <div className="mt-4 md:mt-0 flex gap-6">
            <a href="https://github.com/Kubar-Labs/wager-chess" target="_blank" className="hover:text-white transition-colors">GitHub</a>
            <a href="https://monad-foundation.notion.site/Resources-c716367594f283b1832681536dcf6d84" target="_blank" className="hover:text-white transition-colors">Monad Docs</a>
          </div>
        </div>
      </footer>
    </div>
  );
}
