import App, { type WebSocketData } from "./app";
import { DAO } from "./DAO";
import { getRandomInt } from "./util";

const pidFile = Bun.file('server.pid')
if (await pidFile.exists()) {
  const pidStr = await pidFile.text()
  const pid = parseInt(pidStr)
  if (!isNaN(pid)) {
    try {
      console.log(`Killing old server process: ${pid}`)
      process.kill(pid, 'SIGKILL')
      console.log('Process killed')
    } catch (error) {
      console.log(`Process ${pid} could not be killed because it does not exist.`)
    }
  }
}


const db = new DAO()
await db.connect()

const server = Bun.serve<WebSocketData>({
  hostname: process.env.APP_HOSTNAME ?? "0.0.0.0",
  port: process.env.APP_PORT ?? 8000,
  fetch(req, server) {
    if (server.upgrade(req, {
      data: {
        id: getRandomInt()
      }
    })) {
      return
    }

    return new Response("Expected a WebSocket connection", { status: 400 });
  },
  websocket: {
    open(ws) {
      ws.data.app = new App(ws, db)
      ws.data.app.connected()
    },
    async message(ws, message) {
      await ws.data.app?.message(message)
    },
    close(ws, code, message) {
      ws.data.app?.disconnected(code, message)
    },
  },
});


await pidFile.write(process.pid.toString())
console.log(`WebSocket server started listening on ws://${server.hostname}:${server.port}`);
