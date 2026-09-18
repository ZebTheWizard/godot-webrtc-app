import type { AuthRequest, Request } from "./app";
import { DAO } from "./DAO";

export function auth(
  target: any,
  propertyKey: string,
  descriptor: PropertyDescriptor
) {
  const originalMethod = descriptor.value;

  descriptor.value = async function (req: AuthRequest, ...args: any[]) {
    req.player = await this.db.getPlayerByClientId(this.id);

    if (!req.player) {
      throw new Error("Authentication required");
    }

    return await originalMethod.call(this, req, ...args);
  };

  return descriptor;
}
