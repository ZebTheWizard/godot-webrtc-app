import z from "zod";
import type { ClientMessage } from "./app";
import type App from "./app";
import type { DAO, Player } from "./DAO";
import { message } from "./enum";
import { ValidationError } from "./ValidationError";

export class Controller {
  private app: App
  protected id: number
  protected db: DAO

  constructor(app: App, message:ClientMessage) {
    this.app = app
    this.id = message.id
    this.db = app.getDB()
  }

  async validate<T extends z.ZodObject>(
    schema: T,
    rawData: unknown
  ): Promise<z.output<T> | never> {
    const validated: z.ZodSafeParseResult<z.output<T>> = await schema.safeParseAsync(rawData);
    if (!validated.success) {
      const fieldErrors: Record<string, string> = {};

      for (const issue of validated.error.issues) {
        for (const path of issue.path) {
          if (path && typeof path === "string" && !fieldErrors[path]) {
            fieldErrors[path] = issue.message;
          }
        }
      }

      throw new ValidationError(fieldErrors)
    }
    return validated.data
  }

  // auth() {
  //   return z.optional(z.any()).transform(async (_, ctx) => {
  //     const player = await this.db.getPlayerByClientId(this.id);
  //     if (!player) {
  //       ctx.addIssue({
  //         code: z.ZodIssueCode.custom,
  //         message: "Player not found",
  //       });
  //       return z.NEVER;
  //     }
  //     return player;
  //   });
  // }

  emit(json:any) {
    return this.app.emit(json)
  }

  broadcast(json: any) {
    return this.app.broadcast(json)
  }

  emitTo(client_id: number, json: any) {
    return this.app.emitTo(client_id, json)
  }
}
