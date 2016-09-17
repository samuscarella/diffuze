var http = require('http');
var logic = require("./logic.js")

const PORT = 9000;

//We need a function which handles requests and send response
function handleRequest(request, response){
    response.end('It Works!! Path Hit: ' + request.url);
}
///////////////////////// End of Logic

//Create a server
var server = http.createServer(handleRequest);
//Lets start our server
server.listen(PORT, function(){
    //Callback triggered when server is successfully listening. Hurray!
    console.log("InfoBomb-Development listening on: http://localhost:%s", PORT);
});
