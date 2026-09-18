import { dateFormatter, startTime } from "./util";
import { message as messageType } from "./enum";
import { MessageController } from "./MessageController";
import type { DAO, Player } from "./DAO";
import { ValidationError } from "./ValidationError";

const clients: Record<number, WebSocket> = {}

export type WebSocketData = {
  id: number;
  app?: App
}

type WebSocket = Bun.ServerWebSocket<WebSocketData>

export type ClientMessage = {
  id: number,
  type: messageType,
  data: object
}

export type Request<T = {}> = {
  type: messageType,
  data: unknown
} & T

export type AuthRequest<T = {}> = Request<{
  player?: Player
}> & T

export default class App {
  private ws: WebSocket;
  private id: number;
  private db: DAO

  constructor(ws:WebSocket, db:DAO) {
    this.ws = ws
    this.id = ws.data.id
    clients[ws.data.id] = ws
    this.db = db
  }

  getDB():DAO {
    return this.db
  }

  connected() {
    this.emit({
      type: messageType.ID,
      data: {
        id: this.id
      }
    })
  }

  async message(message:string | Buffer<ArrayBuffer>) {
    console.log(`Received from ${this.id}: ${message}`);
    const dataStr:string = typeof message === 'string' ? message : new TextDecoder().decode(message)
    try {
      const msg = JSON.parse(dataStr)

      // if (typeof msg.id !== 'number' || !(msg.id in clients)) {
      //   throw new Error('Message parsing error: Invalid ID')
      // }

      if (typeof msg.type !== 'number' || !(msg.type in messageType)) {
        throw new Error('Message parsing error: Invalid type')
      }

      if (!(typeof msg.data === 'object' || typeof msg.data === 'undefined')) {
        throw new Error('Message parsing error: Invalid data')
      }

      const req = {
        type: msg.type,
        data: msg.data ?? {},
      }
      const controller = new MessageController(this, msg)

      switch (msg.type) {
        case messageType.LOGIN:
          await controller.login(req)
          break
        case messageType.SIGNUP:
          await controller.signup(req)
          break
        case messageType.MATCH_CREATE:
          await controller.matchCreate(req)
          break
        case messageType.MATCH_LIST:
          await controller.matchList(req)
          break
        case messageType.MATCH_JOIN:
          await controller.matchJoin(req)
          break
        case messageType.LOBBY:
          await controller.getLobby(req)
          break
        case messageType.MATCH_LEAVE:
          await controller.matchLeave(req)
          break
        case messageType.MATCH_START:
          await controller.matchStart(req)
          break
        case messageType.WEBRTC_OFFER:
        case messageType.WEBRTC_ANSWER:
        case messageType.WEBRTC_EXCHANGE:
          await controller.relayWebRTC(req)
          break
        default:
          console.log(dataStr)
      }
    } catch (error) {
      if (error instanceof ValidationError) {
        this.emit({
          type: messageType.ERROR,
          data: error.errors
        })
      } else if (error instanceof Error) {
        console.error(error)
        this.emit({
          type: messageType.ERROR,
          data: {
            exception: `${error.name}: ${error.message}`
          }
        })
      }
    }

  }

  disconnected(code:number, message:string) {
    console.log(`Client ${this.id} disconnected with code ${code} ${message}`)
    delete clients[this.id]
  }

  emit(json:any) {
    const jsonString = JSON.stringify(json);
    const buffer = new TextEncoder().encode(jsonString);
    console.log(`emitting to ${this.id}: ${jsonString}`)
    this.ws.send(buffer)
  }

  broadcast(json: any) {
    const jsonString = JSON.stringify(json);
    const buffer = new TextEncoder().encode(jsonString);
    console.log(`broadcasting: ${jsonString}`)
    for (const client of Object.values(clients)) {
      client.send(buffer)
    }
  }

  emitTo(clientId: number, json: any) {
    const client: WebSocket = clients[clientId]
    if (typeof client === 'undefined') {
      throw new Error(`Could not find client with id of ${client_id}`)
    }
    const jsonString = JSON.stringify(json);
    const buffer = new TextEncoder().encode(jsonString);
    console.log(`emitting to ${clientId}: ${jsonString}`)
    client.send(buffer)
  }
}
