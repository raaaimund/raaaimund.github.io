---
layout:     post
title:      Basics in Angular and Node (Part 1)
date:       2016-06-18 19:00:00
author:     Raimund Rittnauer / Andreas Rosegger
summary:    todo
categories: tech
thumbnail:  heart
comments: true
tags:
 - angular
 - node
---

## Stuff we need
You just need [nodejs][1]{:target="_blank"}, on their homepage they got a great tutorial how to install
and how to get started.

## Init our project
Start your favorite IDE ([WebStorm][2]{:target="_blank"}) and start with literally nothing (empty project),
grab your terminal (Alt+F12 in WebStorm), type 'npm init' and hit enter.
Now a new file called 'package.json' should be created where all your
info about your project is stored.
For the next step we need express. Switch to your terminal again and type
'npm install -S express'. The dependency should be added automatically to your
package.json because of our '-S' flag.

## Integrate express
Create your entrypoint javascript file (default 'index.js', we defined 'server.js')
and fill it with code.

__server.js__
{% highlight ruby %}
express = require('express');

app = express();

app.get("/", function(req, res) {
    res.send("hello world");
});

app.listen(3000);
{% endhighlight %}

Now you have your first express app and can browse to [http://localhost:3000][8]{:target="_blank"} to see
your output.

## Integrate Angular
Create a folder called public, an index.html and an app.js file inside our new public folder.

In our app.js we create a new module and a controller for our app.

__app.js__
{% highlight ruby %}
angular.module("pubertown", [])
    .controller("mainctrl", function($scope) {
        $scope.text = "Hello World";
    });
{% endhighlight %}

In our index.html we have to include the [Angular CDN][9]{:target="_blank"} and our app.js file.
After that we only have to add a new ng-app property (the value is the name
of our module) to our html tag and a ng-controller property (the value is
the name of our controller) to our body tag.

Now we can use template style syntax to access our fields in our fancy scope.

__index.html__
{% highlight ruby %}
<!DOCTYPE html>
<html lang="en" ng-app="pubertown">
<head>
    <meta charset="UTF-8">
    <title>Pubertown</title>

    <script src="https://ajax.googleapis.com/ajax/libs/angularjs/1.5.6/angular.min.js"></script>
    <script src="app.js"></script>
</head>
<body ng-controller="mainctrl">
    {{ text }}
</body>
</html>
{% endhighlight %}

Don't forget to restart the server, checkout your new app with Angular at your [http://localhost:3000][8]{:target="_blank"}.

## Add functionality
Now we want to use the basics of Angular to add values to a list.
We need to add to our index.html a inputfield for our values and a button which calls a
function to add the current value to our list, we also need a list to populate our values.

__index.html__
{% highlight ruby %}
<!DOCTYPE html>
<html lang="en" ng-app="pubertown">
<head>
    <meta charset="UTF-8">
    <title>Pubertown</title>

    <script src="https://ajax.googleapis.com/ajax/libs/angularjs/1.5.6/angular.min.js"></script>
    <script src="app.js"></script>
</head>
<body ng-controller="mainctrl">
    <input type="text" ng-model="txtField" />
    <button ng-click="addText()">Add</button>

    <ul>
        <li ng-repeat="item in items">{{ item }}</li>
    </ul>
</body>
</html>
{% endhighlight %}

After updating our index.html we should take a look on our new node app with
express and server. Just restart your server again and take a look at
[http://localhost:3000][8]{:target="_blank"}.

On the next part we will integrate [mongodb][3]{:target="_blank"} and add the functionality to add
images to each entry. We will store all the images on our own [cdn][4]{:target="_blank"} with
[nginx][5]{:target="_blank"} in a Docker container on our Fedora server.

You can find the [source code][7]{:target="_blank"} from this part in my github repo.

[1]: https://nodejs.org
[2]: https://www.jetbrains.com/webstorm/
[3]: https://www.mongodb.com/
[4]: https://en.wikipedia.org/wiki/Content_delivery_network
[5]: https://nginx.org/
[7]: https://github.com/raaaimund/raaaimund.github.io/tree/master/assets/blog-files/basics-in-angular-and-node
[8]: http://localhost:3000
[9]: https://docs.angularjs.org/misc/downloading