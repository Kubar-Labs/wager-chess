"use client";

import { useState } from "react";

interface DashboardProps {
  potSize?: string;
  personalSpend?: string;
}

export function Dashboard({
  potSize = "0.00",
  personalSpend = "0.00",
}: DashboardProps) {
  const [mockPotSize] = useState(potSize);
  const [mockPersonalSpend] = useState(personalSpend);

  return (
    <div className="flex flex-col gap-4">
      <div className="rounded-xl bg-surface border border-border p-6">
        <h2 className="text-lg font-semibold text-foreground mb-4">
          Game Stats
        </h2>
        <div className="grid grid-cols-1 gap-4">
          <div className="rounded-lg bg-surface-raised p-4 border border-border">
            <span className="text-sm font-medium text-zinc-400">Pot Size</span>
            <div className="mt-1 flex items-baseline gap-1">
              <span className="text-2xl font-bold text-accent">
                {mockPotSize}
              </span>
              <span className="text-sm text-zinc-400">MON</span>
            </div>
          </div>

          <div className="rounded-lg bg-surface-raised p-4 border border-border">
            <span className="text-sm font-medium text-zinc-400">
              Your Spend
            </span>
            <div className="mt-1 flex items-baseline gap-1">
              <span className="text-2xl font-bold text-foreground">
                {mockPersonalSpend}
              </span>
              <span className="text-sm text-zinc-400">MON</span>
            </div>
          </div>

          <div className="rounded-lg bg-surface-raised p-4 border border-border">
            <span className="text-sm font-medium text-zinc-400">
              Move Cost
            </span>
            <div className="mt-1 flex items-baseline gap-1">
              <span className="text-2xl font-bold text-foreground">0.01</span>
              <span className="text-sm text-zinc-400">MON / move</span>
            </div>
          </div>
        </div>
      </div>

      <div className="rounded-xl bg-surface border border-border p-6">
        <h2 className="text-lg font-semibold text-foreground mb-4">
          How to Play
        </h2>
        <ul className="space-y-2 text-sm text-zinc-400">
          <li className="flex items-start gap-2">
            <span className="mt-0.5 inline-flex h-5 w-5 items-center justify-center rounded-full bg-accent/20 text-xs font-bold text-accent">
              1
            </span>
            Connect your wallet
          </li>
          <li className="flex items-start gap-2">
            <span className="mt-0.5 inline-flex h-5 w-5 items-center justify-center rounded-full bg-accent/20 text-xs font-bold text-accent">
              2
            </span>
            Each move costs MON tokens
          </li>
          <li className="flex items-start gap-2">
            <span className="mt-0.5 inline-flex h-5 w-5 items-center justify-center rounded-full bg-accent/20 text-xs font-bold text-accent">
              3
            </span>
            Winner takes the pot
          </li>
        </ul>
      </div>
    </div>
  );
}
