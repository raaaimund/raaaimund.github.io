---
permalink:	/:categories/:year/:month/:day/:title/
layout:     post
title:      Style your Blazor components with SCSS and Web Compiler
date:       2019-11-18 21:42:00
author:     Raimund Rittnauer
description:    How to use Web Compiler to style your Blazor components with Sassy CSS
categories: tech
comments: true
tags:
 - blazor
 - scss
 - webcompiler
 - netcore3.0
---

In this post we use [Sassy CSS][1]{:target="_blank"} to style our Blazor components and we will integrate [Web Compiler][2]{:target="_blank"} to compile these files to a single file _site.css_. Web Compiler easily integrates with your .Net Core project and also lets you compile SCSS to CSS during a build.

> The only downside of Web Compiler is, that you can't use it (at the moment) if you plan to build your code on a linux machine. See this [GitHub issue][3]{:target="_blank"} for more information.

If you want to build on a linux machine see my other post for [styling your Blazor components with SCSS and Web Optimizer][6]{:target="_blank"}.

In our server side .Net Core 3.0 Blazor project we got the following project structure

* BlazorStyling.WebCompiler
    * wwwroot/
        * css/
    * Components/
        * Progress.razor
        * Progress.scss
    * Pages/
        * _Host.cshtml
        * Index.razor
    * Shared/
        * Helper.scss
        * MainLayout.razor
    * _Imports.razor
    * App.razor
    * App.scss
    * appsettings.json
    * Program.cs
    * Startup.cs

We use SCSS to style a progress bar Blazor component __Progress.razor__

``` razor
<div class="progress">
    <div class="progress-bar @BackgroundClass"
         role="progressbar"
         style="width: @Width"
         aria-valuenow="@ValueNow"
         aria-valuemin="0"
         aria-valuemax="100">
    </div>
</div>

@code {
    public enum BackgroundColor { Red, Yellow, Green }

    [Parameter]
    public int ValueNow { get; set; }
    [Parameter]
    public BackgroundColor BgColor { get; set; } = BackgroundColor.Green;

    private string BackgroundClass => $"bg-{BgColor.ToString().ToLower()}";
    private string Width => $"{ValueNow}%";
}
```

with its style __Progress.scss__.

``` scss
.progress {
    display: flex;
    height: 1rem;
    overflow: hidden;
    font-size: .75rem;
    background-color: #e9ecef;
    border-radius: .25rem;
}

.progress-bar {
    display: flex;
    flex-direction: column;
    justify-content: center;
    color: #fff;
    text-align: center;
    white-space: nowrap;
    background-color: #007bff;
    transition: width .6s ease;
}

$bg-green: #28a745;
$bg-yellow: #ffc107;
$bg-red: #dc3545;

.bg {
    &-green {
        background-color: $bg-green;
    }

    &-yellow {
        background-color: $bg-yellow;
    }

    &-red {
        background-color: $bg-red;
    }
}
```

The index page __Index.razor__ renders three progress bar components with different colors

``` razor
@page "/"

<div class="mt-1">
    <Progress ValueNow="25" BgColor="Progress.BackgroundColor.Green" />
</div>
<div class="mt-1">
    <Progress ValueNow="50" BgColor="Progress.BackgroundColor.Red" />
</div>
<div class="mt-1">
    <Progress ValueNow="75" BgColor="Progress.BackgroundColor.Yellow" />
</div>
```

and we need a root SCSS file __App.scss__ to combine all other SCSS files.

``` scss
@import 'Components/Progress';
@import 'Shared/Helper';
```

The __MainLayout.razor__ is nearly empty

``` razor
@inherits LayoutComponentBase

@Body
```

and our __Host.cshtml__ just renders the app and includes the compiled css.

``` cshtml
@page "/"
@namespace BlazorStyling.WebCompiler.Pages
@addTagHelper *, Microsoft.AspNetCore.Mvc.TagHelpers

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>BlazorStyling.WebCompiler</title>
    <base href="~/" />
    <environment include="Development">
        <link href="css/site.css" rel="stylesheet" />
    </environment>
    <environment exclude="Development">
        <link href="css/site.min.css" rel="stylesheet" />
    </environment>
</head>
<body>
    <app>
        @(await Html.RenderComponentAsync<App>(RenderMode.ServerPrerendered))
    </app>

    <script src="_framework/blazor.server.js"></script>
</body>
</html>
```

With this set up, we can install the [Web Compiler Visual Studio Extension][4]{:target="_blank"}. After restarting Visual Studio, just right click on your __App.scss__ file and choose _Web Compiler -> Compile File_ or <kbd>Shift</kbd>+<kbd>Alt</kbd>+<kbd>Q</kbd>.

With the generated configuration file __compilerconfig.json__ we can configure Web Compiler and on save Web Compiler should compile your SCSS files to CSS and generate a site.css file in _wwwroot/css/__.

``` json
[
  {
    "outputFile": "wwwroot/css/site.css",
    "inputFile": "App.scss",
    "minify": {
      "enabled": true
    },
    "options": {
      "sourceMap": true
    }
  }
]
```

To run Web Compiler before a build you have to install a NuGet Package or right click on __compilerconfig.json__ and choose _Web Compiler -> Enable compile on build..._, which also installs this NuGet package, but probably with a newer version.

``` xml
<PackageReference Include="BuildWebCompiler" Version="1.12.394" />
```

Now open the _Task Runner Explorer_ (_Views -> Other Windows -> Task Runner Explorer_) and right click on your __App.scss__ and choose _Bindings -> Before Build_.

![compile before build][compile-before-build]

This project is available on [GitHub][5]{:target="_blank"}.

[1]: https://sass-lang.com/
[2]: https://github.com/madskristensen/WebCompiler
[3]: https://github.com/madskristensen/WebCompiler/issues/354#issuecomment-466254831
[4]: https://marketplace.visualstudio.com/items?itemName=MadsKristensen.WebCompiler
[5]: https://github.com/raaaimund/BlazorStyling/tree/blazor-components-scss-webcompiler
[6]: {% post_url 2019-11-19-blazor-components-scss-weboptimizer %}

[compile-before-build]: {{ site.baseurl }}/assets/img/2019-11-18-blazor-components-scss-webcompiler/compile-before-build.gif "compile before build"
