

import { init } from "@dojoengine/sdk";
import type { SchemaType } from "../generated/models.gen";
import { schema } from "../generated/models.gen";
import { dojoConfig } from "../config/dojoConfig";

type DojoDb = Awaited<ReturnType<typeof init<SchemaType>>>;
let dbPromise!: Promise<DojoDb>;

/**
 * Returns a singleton Database instance. Subsequent calls return the same pending promise.
 */
export function getDojoDb(): Promise<DojoDb> {
  if (!dbPromise) {
    dbPromise = init<SchemaType>({
      client: {
        toriiUrl: dojoConfig.toriiUrl,
        relayUrl: dojoConfig.relayUrl,
        worldAddress: dojoConfig.manifest.world.address,
      },
      domain: {
        name: "PojoApp",
        version: "1.0",
        chainId: dojoConfig.chainId,
        revision: "1",
      },
      schema,
    });
  }
  return dbPromise;
}
