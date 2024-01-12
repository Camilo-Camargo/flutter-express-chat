import express from "express"
import { Server } from "socket.io"
import HTTP from "http"

const app = express();
app.use(express.json());
const http = HTTP.createServer(app);
const socket = new Server(http);
const port = 3000;
const generalRoom = "general";

// database
const database = {
  rooms: {
    general: [],
  },
  users: {
    miguel: {
      rooms: ["general", "sala 1", "sala 2"]
    },
    lucy: {
      rooms: ["general"]
    }
  }
};

// endpoints
app.get('/message', (req, res) => {

  const userId = req.body.id;
  const room = req.body.room;

  // verify if the user has access to the room
  const rooms = database.users[userId].rooms;
  if(!rooms.includes(room)){
    res.status(401).send({status: 401, msg: "Unauthorized"});
  }

  res.send({messages: database.rooms[room]});
});

app.post('/message', (req, res) => {
  const userId = req.body.id;
  const room = req.body.room;
  const msg = req.body.msg;

  // verify if the user has access to the room
  const rooms = database.users[userId].rooms;
  if(!rooms.includes(room)){
    res.status(401).send({status: 401, msg: "Unauthorized"});
  }

  database.rooms[room].push({id: userId, msg: msg});
  socket.to(room).emit('msg:new', JSON.stringify({id: userId, room: room}))

  res.status(200).send({status: 200, msg: `Message write by ${userId} has been saved and sent`});
});

socket.on('connection', async (user) => {
  console.log("Socket connected");
  console.log(user.id);


  // query database for user rooms (turns)
  const userId = user.request.headers.id;
  const rooms = database.users[userId].rooms;
  for (const room of rooms) {
    await user.join(room);
    console.log(`${userId} join to General ${room}`);
  }
  

  /*
  user.on('received', (msg) => {
    console.log(msg);
  });
  */


});

http.listen(port, () => {
  console.log(`Chat Server running at ${port}`);
})

