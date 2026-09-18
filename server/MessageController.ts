import { hash, verify } from "argon2";
import { Controller } from "./Controller";
import { map, match_status, match_type, message } from "./enum";
import z from "zod";
import { auth } from "./decorators";
import type { Player } from "./DAO";
import type { AuthRequest, Request } from "./app";

export class MessageController extends Controller {

  async login(req: Request) {
    var schema = z.object({
      username: z.string().min(3, "Username must be at least 3 characters long."),
      password: z.string().min(8, "Password must be at least 8 characters long."),
    }).refine(async (data) => {
      const player = await this.db.getPlayerByUsername(data.username)
      return player && (await verify(player.password, data.password))
    }, {
      message: "Invalid username or password.",
      path: ["username", "password"]
    })

    const validated = await this.validate(schema, req.data)

    await this.db.updatePlayerByUsername(validated.username, {
      'client_id': this.id
    })

    const updatedPlayer = await this.db.getPlayerByClientId(this.id)
    if (!updatedPlayer) return

    this.emit({
      type: message.LOGIN_SUCCESS,
      data: updatedPlayer
    })
  }

  async signup(req: Request) {
    var schema = z.object({
      username: z.string().min(3, "Username must be at least 3 characters long."),
      password: z.string().min(8, "Password must be at least 8 characters long."),
      password_confirm: z.string()
    }).refine((data) => data.password === data.password_confirm, {
      message: "Passwords do not match.",
      path: ["password"]
    }).refine(async (data) => !(await this.db.getPlayerByUsername(data.username)), {
      message: "Username already exists.",
      path: ["username"]
    })

    const validated = await this.validate(schema, req.data)

    const player = await this.db.insertPlayer({
      username: validated.username,
      password: await hash(validated.password),
      client_id: this.id
    })

    if (!player) return

    this.emit({
      type: message.SIGNUP_SUCCESS
    })

  }

  @auth
  async matchCreate(req: AuthRequest) {
    const schema = z.object({
      name: z.string().min(3),
      password: z.string(),
      map: z.preprocess((val) => !val ? map.DEFAULT : val, z.enum(map, 'Invalid map')),
      type: z.preprocess((val) => !val ? match_type.FFA : val, z.enum(match_type, 'Invalid match type'))
    })

    const validated = await this.validate(schema, req.data)

    const match = await this.db.insertMatch({
      name: validated.name,
      map: validated.map,
      type: validated.type,
      status: match_status.IN_PROGRESS,
      password: await hash(validated.password),
      host_id: req.player!.id
    })

    if (typeof match === 'undefined') {
      throw new Error('Match not created')
    }

    this.db.updatePlayerByUsername(req.player!.username, {
      is_host: true,
      match_id: match.id,
      client_id: this.id
    })

    this.broadcast({
      type: message.MATCH_LIST,
      data: await this.db.getMatches()
    })

    this.emit({
      type: message.MATCH_CONNECTED,
      data: match
    })
  }

  async matchList(req:Request) {
    this.emit({
      type: message.MATCH_LIST,
      data: await this.db.getMatches()
    })
  }

  @auth
  async matchJoin(req: AuthRequest) {
    const schema = z.object({
      id: z.uuidv4()
    })

    const validated = await this.validate(schema, req.data)

    const match = await this.db.getMatchById(validated.id)

    if (typeof match === 'undefined') {
      throw new Error('Match not found')
    }

    this.db.updatePlayerByUsername(req.player!.username, {
      match_id: match.id
    })

    this.emit({
      type: message.MATCH_CONNECTED,
      data: match
    })

    const players = await this.db.getPlayersByMatchId(match.id)
    for (const player of players) {
      if (!player.client_id) continue
      this.emitTo(player.client_id, {
        type: message.LOBBY,
        data: players
      })
    }
  }

  async getLobby(req: Request) {
    const schema = z.object({
      id: z.string()
    })

    const validated = await this.validate(schema, req.data)

    this.emit({
      type: message.LOBBY,
      data: await this.db.getPlayersByMatchId(validated.id)
    })
  }

  @auth
  async matchLeave(req: AuthRequest) {
    const { player } = req;
    if (!player?.match_id) return;

    const matchId = player.match_id;
    const players = await this.db.getPlayersByMatchId(matchId);

    if (player.is_host) {
      await this.handleHostLeave(player, players, matchId);
    } else {
      await this.handleNonHostLeave(player, players);
    }
  }

  private async handleHostLeave(
    host: Player,
    players: Player[],
    matchId: string
  ) {
    await this.db.deleteMatchById(matchId);
    await this.db.updatePlayerByUsername(host.username, { is_host: false });

    const matches = await this.db.getMatches();
    this.broadcast({ type: message.MATCH_LIST, data: matches });

    for (const p of players) {
      if (!p.client_id) continue;

      const isOtherPlayer = p.client_id !== host.client_id;
      this.emitTo(p.client_id, {
        type: message.MATCH_DISCONNECTED,
        data: isOtherPlayer ? { message: "The host has left the match." } : {}
      });
    }
  }

  private async handleNonHostLeave(player: Player, players: Player[]) {
    await this.db.updatePlayerByUsername(player.username, {
      is_host: false,
      match_id: null,
    });

    this.emit({ type: message.MATCH_DISCONNECTED });

    const remainingPlayers = players.filter(p => p.client_id !== this.id);
    for (const p of remainingPlayers) {
      if (!p.client_id) continue
      this.emitTo(p.client_id, { type: message.LOBBY, data: players });
    }
  }

  async matchStart(req: Request) {
    const schema = z.object({
      id: z.uuidv4()
    })

    const validated = await this.validate(schema, req.data)

    const players = await this.db.getPlayersByMatchId(validated.id)
    const host = players.find(p => p.is_host)

    console.log('wanting to start match', {
      id: validated.id,
      players: players.map(x => x.username),
      host: host?.username
    })

    if (!host) return
    if (host.client_id !== this.id) return

    for (const player of players) {
      if (!player.client_id) continue
      const peers = players.filter(p => p.client_id !== player.client_id)
      this.emitTo(player.client_id, {
        type: message.MATCH_START,
        data: peers
      })
    }
  }

  async relayWebRTC(req: Request) {
    const schema = z.object({
      peer: z.number()
    })

    const validated = await this.validate(schema, req.data)

    this.emitTo(validated.peer, req)
  }
}
