// Basic Dojo configuration used by the SDK initialiser.
// TODO: Replace the placeholder URLs / addresses with the ones for your deployment.
// You can also move these values to environment variables if preferred.

export const dojoConfig = {
  toriiUrl: "https://api.torii.dojoengine.org", // Torii gRPC gateway
  relayUrl: "https://api.relay.dojoengine.org", // Relayer endpoint for signed txs
  // The manifest is produced when you deploy your world with sozo.
  // Paste the generated manifest JSON here or import it.
  manifest: {
    world: {
      address: "0x0000000000000000000000000000000000000000"
    }
  },
  // EVM-style chain id.
  chainId: "dojo-testnet"
} as const;
