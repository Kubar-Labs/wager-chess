"use client";

import { useAccount, useConnect, useDisconnect, useBalance } from "wagmi";
import { injected } from "wagmi/connectors";
import { formatUnits } from "viem";

export function ConnectWallet() {
  const { address, isConnected } = useAccount();
  const { connect, isPending } = useConnect();
  const { disconnect } = useDisconnect();
  const { data: balance } = useBalance({ address });

  const formattedBalance = balance
    ? formatUnits(balance.value, balance.decimals)
    : "0";

  if (isConnected && address) {
    return (
      <div className="flex items-center gap-4">
        <div className="flex flex-col items-end">
          <span className="text-sm font-medium text-foreground">
            {address.slice(0, 6)}...{address.slice(-4)}
          </span>
          <span className="text-xs text-zinc-400">
            {formattedBalance} {balance?.symbol ?? "MON"}
          </span>
        </div>
        <button
          onClick={() => disconnect()}
          className="rounded-lg bg-surface-raised px-4 py-2 text-sm font-medium text-foreground transition-colors hover:bg-border border border-border"
        >
          Disconnect
        </button>
      </div>
    );
  }

  return (
    <button
      onClick={() => connect({ connector: injected() })}
      disabled={isPending}
      className="rounded-lg bg-accent px-5 py-2.5 text-sm font-semibold text-white transition-colors hover:bg-accent-hover disabled:opacity-50"
    >
      {isPending ? "Connecting..." : "Connect Wallet"}
    </button>
  );
}
