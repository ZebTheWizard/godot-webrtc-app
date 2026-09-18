import { hash } from "argon2";
import { Database, open, type ISqlite } from "sqlite";
import sqlite3 from "sqlite3";
import type { map, match_status, match_type } from "./enum";

export type Player = {
  id: string,
  username: string,
  password: string,
  client_id?: number,
  is_host: boolean,
  team?: number,
  match_id?: string
}

export type Match = {
  id: string,
  name: string,
  password: string,
  map: map,
  status: match_status
  type: match_type
  host_id: string,
}

export class DAO {
  private db?: Database

  async connect() {
    this.db = await open({
      filename: process.env.DB_FILE ?? './database.db',
      driver: sqlite3.Database,
    });

    await this.db.exec('PRAGMA foreign_keys = ON')

    await this.db.migrate({
      migrationsPath: './server/migrations',
      force: process.env.APP_DEBUG == 'true',
    });

    const { playerCount } = await this.db.get('SELECT COUNT(*) as playerCount FROM players')
    if (playerCount <= 0) {
      await this.insertPlayer({ username: 'john', password: await hash('password') })
      await this.insertPlayer({ username: 'bob', password: await hash('password') })
      await this.insertPlayer({ username: 'frank', password: await hash('password') })
      await this.insertPlayer({ username: 'jim', password: await hash('password') })
    } else {
      await this.updateRows('players', { is_host: false })
    }
  }

  async insertPlayer(data: Record<string, any>): Promise<Player | undefined> {
    const id = crypto.randomUUID()
    await this.insertRow('players', {
      'id': id,
      'username': data.username,
      'password': data.password,
      'client_id': data.client_id,
      'is_host': data.is_host ?? false,
      'team': data.team,
      'match_id': data.team
    })

    return await this.getPlayerById(id)
  }

  async updatePlayerByUsername(username: string, data: Record<string, any>) {
    return await this.updateRows('players', 'username = ?', data, username)
  }

  async getPlayerById(id: string): Promise<Player | undefined> {
    return await this.db!.get('SELECT * FROM players WHERE id = ?', id)
  }

  async getPlayerByUsername(username: string): Promise<Player | undefined> {
    return await this.db!.get('SELECT * FROM players WHERE username = ?', username)
  }

  async getPlayerByClientId(id: number): Promise<Player | undefined> {
    return await this.db!.get('SELECT * FROM players WHERE client_id = ?', id)
  }

  async getPlayersByMatchId(id: string): Promise<Player[]> {
    return await this.db!.all("SELECT * FROM players WHERE match_id = ?", id)
  }

  async insertMatch(data: Record<string, any>): Promise<Match | undefined> {
    const id = crypto.randomUUID()
    await this.insertRow('matches', {
      'id': id,
      'name': data.name,
      'password': data.password,
      'map': data.map,
      'status': data.status,
      'type': data.type,
      'host_id': data.host_id,
    })

    return await this.getMatchById(id)
  }

  async deleteMatchById(id: string) {
    return await this.deleteRows('matches', 'id = ?', id)
  }

  async getMatchById(id: string): Promise<Match | undefined> {
    return await this.db!.get('SELECT players.client_id as host_client_id, matches.* FROM matches JOIN players ON players.id = matches.host_id WHERE matches.id = ?', id)
  }

  async getMatches(): Promise<Match[]> {
    return await this.db!.all('SELECT * FROM matches')
  }

  async insertRow(table: string, data: Record<string, any>) {
    const columns: string[] = []
    const values: string[] = []
    const bindings: any[] = []

    for (const key in data) {
      columns.push(key)
      bindings.push(data[key])
      values.push('?')
    }

    const query = `INSERT INTO ${table} (${columns.join(', ')}) VALUES (${values.join(', ')})`
    return await this.db!.run(query, ...bindings)
  }

  async updateRows(table: string, data: Record<string, any>): Promise<ISqlite.RunResult<sqlite3.Statement>>;
  async updateRows(table: string, condition: string, data: Record<string, any>, ...conditionBindings: any[]): Promise<ISqlite.RunResult<sqlite3.Statement>>;
  async updateRows( table: string,conditionOrData: string | Record<string, any>, dataOrBinding?: Record<string, any> | any, ...conditionBindings: any[]): Promise<ISqlite.RunResult<sqlite3.Statement>> {
    let condition: string | undefined;
    let data: Record<string, any>;

    if (typeof conditionOrData === 'string') {
      condition = conditionOrData;
      data = dataOrBinding as Record<string, any>;
    } else {
      data = conditionOrData;
      if (dataOrBinding !== undefined) {
        conditionBindings.unshift(dataOrBinding);
      }
    }

    const setClauses: string[] = []
    const bindings: any[] = []

    for (const key in data) {
      setClauses.push(`${key} = ?`)
      bindings.push(data[key])
    }

    bindings.push(...conditionBindings)

    const statement: string[] = [
      'UPDATE',
      table,
      'SET',
      setClauses.join(', ')
    ]

    if (condition) {
      statement.push(`WHERE ${condition}`)
    }

    const query = statement.join(' ')
    return await this.db!.run(query, ...bindings)
  }

  async deleteRows(table: string, condition: string, ...conditionBindings: any[]) {
    const bindings: any[] = []

    bindings.push(...conditionBindings)
    const query = `DELETE FROM ${table} WHERE ${condition}`
    return await this.db!.run(query, ...bindings)
  }
}
