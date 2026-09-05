const startTime = new Date()

const dateFormatter = new Intl.DateTimeFormat('en-US', {
  year: 'numeric',
  month: '2-digit',
  day: '2-digit',
  hour: '2-digit',
  minute: '2-digit',
  second: '2-digit',
  hour12: false // Ensures 24-hour format
});

const server = Bun.serve({
  port: 8000,
  fetch(req, server) {
    if (server.upgrade(req)) {
      return
    }

    return new Response("Expected a WebSocket connection", { status: 400 });
  },
  websocket: {
    open(ws) {
      console.log("Client connected");
      ws.send(`Welcome to the WebSocket server! ${dateFormatter.format(startTime)}`);
    },
    message(ws, message) {
      console.log(`Received: ${message}`);
      // Echo the message back to the client
      ws.send(`echo: ${message}`);
    },
    close(ws, code, message) {
      console.log("Client disconnected");
    },
  },
});

console.log(`WebSocket server listening on ws://localhost:${server.port}`);
