var firebase = require("firebase");
var geolib = require("geolib");

var config = {
  apiKey: "AIzaSyABB5NRNFkqmNAk8AAKZ4-brJpCdYPsM6w",
  authDomain: "infobomb-9b66c.firebaseapp.com",
  databaseURL: "https://infobomb-9b66c.firebaseio.com",
  storageBucket: "gs://infobomb-9b66c.appspot.com",
};
var secondaryApp = firebase.initializeApp(config);
var database = secondaryApp.database()

///////////////////////// Logic
var activePostsRef = firebase.database().ref("active-posts");
var usersRef = firebase.database().ref("users");

function getAllUsers(callback) {

  var usersArray = []
    usersRef.once('value', function(snapshot) {
        // later implement a wait for the post added below until all users are in the array
        var users = snapshot
        // console.log(users.val())
        users.forEach(function(user) {
          var user_id = user.val().user_ref
          var userLatitude = user.val().latitude
          var userLongitude = user.val().longitude
          var userSubscriptions = user.val().subscriptions
          usersArray.push({
            "user_id": user_id,
            "latitude": userLatitude,
            "longitude": userLongitude,
            "subscriptions": userSubscriptions
          })
        })
        callback(usersArray);
    })
}

var newItems = false
activePostsRef.on('child_added', function(snapshot) {
    if(!newItems) return;
    var post = snapshot.val()
    console.log("WTF")
    getAllUsers(function(users) {
      console.log("Got all users! There are " + users.length + " users.")

      var counter = 0
      addPostToUsersWithinDistance(users, post, function checkUsers(usersThatGotPost) {
          console.log(usersThatGotPost)
          if(counter < 4) {
            post["distance"] += 50
            console.log(post["distance"])
            counter++
            addPostToUsersWithinDistance(users, post, checkUsers)
          }
      })


    })
});
activePostsRef.once("child_added", function(messages) {
  newItems = true
})

function addPostToUsersWithinDistance(users, post, callback) {

      console.log("eekie bookie doo")
      var postCategoriesArray = post["categories"]
      // var postLikes = post.val().likes
      // var postDislikes = post.val().dislikes
      var postDistance = post["distance"]
      var postLatitude = post["latitude"]
      var postLongitude = post["longitude"]
      var createdAt = post["created_at"]
      var currentTime = new Date().getTime()
      // var userInteraction = postLikes + postDislikes
      var usersInRadius = 0
      var usersThatGotPost = 0
      var categoriesOfPost = []

      postCategoriesArray.forEach(function(categoryObj) {
        var categoryName = Object.keys(categoryObj)
        var categoryString = categoryName.toString()
        categoriesOfPost.push(categoryString)
      })

      users.forEach(function(user) {

        var isUserInRadius = geolib.isPointInCircle(
            {latitude: user["latitude"], longitude: user["longitude"]},
            {latitude: postLatitude, longitude: postLongitude},
            postDistance
          );
          if(!isUserInRadius) {
            return
          }
          usersInRadius++

          doesUserAlreadyHavePost(user, post, function(boolean) {
            console.log(boolean + "user has the post")

            var userSubscriptions = Object.keys(user["subscriptions"])
            var isUserSubscribed = false

            for(var i = 0;i < userSubscriptions.length; i++) {
              for(var j = 0;j < categoriesOfPost.length; j++) {
                if(userSubscriptions[i] == categoriesOfPost[j]) {
                  isUserSubscribed = true
                }
              }
            }
            // var userActivityRef = usersRef.child(user["user_id"]).child("activity")
            // console.log(isUserSubscribed)
            if(isUserSubscribed) {
              var key = firebase.database().ref().child("user-activity-feed").child(user["user_id"]).push().key
              console.log(key)
              var updates = {}
              updates["/user-activity-feed/" + user["user_id"] + "/" + key] = post
              firebase.database().ref().update(updates)
              usersThatGotPost++
            }
            callback(usersThatGotPost)
          })
          // if(doesUserAlreadyHavePost) {
          //   return
          // }
          // var userSubscriptions = Object.keys(user["subscriptions"])
          // var isUserSubscribed = false
          //
          // for(var i = 0;i < userSubscriptions.length; i++) {
          //   for(var j = 0;j < categoriesOfPost.length; j++) {
          //     if(userSubscriptions[i] == categoriesOfPost[j]) {
          //       isUserSubscribed = true
          //     }
          //   }
          // }
          // // var userActivityRef = usersRef.child(user["user_id"]).child("activity")
          // // console.log(isUserSubscribed)
          // if(isUserSubscribed) {
          //   var key = firebase.database().ref().child("user-activity-feed").child(user["user_id"]).push().key
          //   console.log(key)
          //   var updates = {}
          //   updates["/user-activity-feed/" + user["user_id"] + "/" + key] = post
          //   firebase.database().ref().update(updates)
          //   usersThatGotPost++
          // }
          // callback(usersThatGotPost)
      })
        console.log
}

function doesUserAlreadyHavePost(user, post, callback) {
  var doesUserAlreadyHavePost = firebase.database().ref().child("user-activity-feed").child(user["user_id"]).child(post["post_ref"])
  doesUserAlreadyHavePost.once('value').then(function(snapshot) {
    var post = snapshot.val()
    if(post) {
      callback(true)
    } else {
      callback(false)
    }
  })
}

activePostsRef.on('child_changed', function(data) {
    var post = data.val()
    console.log(post)
    // console.log(post + " Post Changed.")
    // console.log(usersArray.count + "???")
    // var categories = post.val().categories
    // var likes = post.val().likes
    // var dislikes = post.val().dislikes
    // var distance = post.val().distance
    // var createdAt = post.val().created_at
    // var currentTime = new Date().getTime()
    // var userInteraction = likes + dislikes
    //
    //   if(userInteraction <= 100) {
    //     var postGrade = Math.floor((likes / userInteraction) * 100)
    //   }
});

// activePostsRef.on('child_removed', function(snapshot) {
//     var post = snapshot
//     console.log(post + " Post Removed.")
//     // console.log(usersArray.count + "???")
//     // var categories = post.val().categories
//     // var likes = post.val().likes
//     // var dislikes = post.val().dislikes
//     // var distance = post.val().distance
//     // var createdAt = post.val().created_at
//     // var currentTime = new Date().getTime()
//     // var userInteraction = likes + dislikes
//     //
//     //   if(userInteraction <= 100) {
//     //     var postGrade = Math.floor((likes / userInteraction) * 100)
//     //   }
// });
