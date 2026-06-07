"use client";

import { createConfig, http } from "wagmi";
import { monadTestnet } from "wagmi/chains";
import { injected } from "wagmi/connectors";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { WagmiProvider as WagmiProviderBase } from "wagmi";
import { ReactNode } from "react";

const monadTestnetCustom = {
  ...monadTestnet,
  id: 10143,
  name: "Monad Testnet",
  rpcUrls: {
    default: { http: ["https://testnet-rpc.monad.xyz/"] },
    public: { http: ["https://testnet-rpc.monad.xyz/"] },
  },
  nativeCurrency: {
    name: "MON",
    symbol: "MON",
    decimals: 18,
  },
} as const;

export const config = createConfig({
  chains: [monadTestnetCustom],
  connectors: [injected()],
  transports: {
    [monadTestnetCustom.id]: http("https://testnet-rpc.monad.xyz/"),
  },
});

const queryClient = new QueryClient();

export function WagmiProvider({ children }: { children: ReactNode }) {
  return (
    <WagmiProviderBase config={config}>
      <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
    </WagmiProviderBase>
  );
}
