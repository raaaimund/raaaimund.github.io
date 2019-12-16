---
permalink:	/:categories/:year/:month/:day/:title/
layout:     post
title:      Style your Blazor components with SCSS and Web Optimizer
date:       2019-11-19 21:42:00
author:     Raimund Rittnauer
description:    How to use Web Optimizer to style your Blazor components with Sassy CSS
categories: tech
comments: true
tags:
 - blazor
 - scss
 - weboptimizer
 - netcore3.0
---

In this post we use [Sassy CSS][1]{:target="_blank"} to style our Blazor components and we will integrate [Web Optimizer][2]{:target="_blank"} to compile these files to a single file __site.css__.

> Web Optimizer is an ASP.Net Core middleware for bundling and minification of CSS and JavaScript files at runtime. With full server-side and client-side caching to ensure high performance. No complicated build process and no hassle.

In our server side .Net Core 3.0 Blazor project we got the following project structure

* BlazorStyling.WebOptimizer
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
        @if (!string.IsNullOrWhiteSpace(Label))
        {
            @string.Format(Label, ValueNow)
        }
    </div>
</div>

@code {
    public enum BackgroundColor { Red, Yellow, Green }

    [Parameter]
    public int ValueNow { get; set; }
    [Parameter]
    public string Label { get; set; }
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

The index page __Index.razor__ just renders the progress bar components

``` razor
@page "/"

<div class="mt-1">
    <Progress ValueNow="ValueNow" BgColor="Progress.BackgroundColor.Green" />
</div>
<div class="mt-1">
    <Progress ValueNow="ValueNow" BgColor="Progress.BackgroundColor.Red" />
</div>
<div class="mt-1">
    <Progress ValueNow="ValueNow" BgColor="Progress.BackgroundColor.Yellow" />
</div>
<div class="mt-1">
    <Progress ValueNow="ValueNow" BgColor="Progress.BackgroundColor.Green" Label="we got {0}%" />
</div>
<div class="mt-1">
    <Progress ValueNow="ValueNow" BgColor="Progress.BackgroundColor.Red" Label="finally {0}%" />
</div>
<div class="mt-1">
    <Progress ValueNow="ValueNow" BgColor="Progress.BackgroundColor.Yellow" Label="{0}%" />
</div>

@code {
    const int From = 0, To = 100;
    int ValueNow { get; set; } = 50;

    protected override Task OnAfterRenderAsync(bool firstRender)
        => InvokeAsync(async () =>
        {
            while (true)
            {
                await System.Threading.Tasks.Task.Delay(2000);
                ValueNow = new Random().Next(From, To);
                StateHasChanged();
            }
        });
}
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

With this set up, we can install the NuGet packages [LigerShark.WebOptimizer.Core][3]{:target="_blank"} and [LigerShark.WebOptimizer.Sass][4]{:target="_blank"}.

```
PM> Install-Package LigerShark.WebOptimizer.Core
PM> Install-Package LigerShark.WebOptimizer.Sass
```

To add the middleware we have to add the Web Compiler services to our service collection in __Startup.cs__

``` c#
public void ConfigureServices(IServiceCollection services)
{
    services.AddRazorPages();
    services.AddServerSideBlazor();
    services.AddWebOptimizer(pipeline =>
    {
        // UseContentRoot only sets the root of the source files
        pipeline.AddScssBundle("/css/site.css", "App.scss").UseContentRoot();
    });
}
```

and add Web Optimizer to the request execution pipeline also in __Startup.cs__.

``` c#
public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
{
    if (env.IsDevelopment())
        app.UseDeveloperExceptionPage();
    else
        app.UseHsts();

    app.UseHttpsRedirection();
    app.UseWebOptimizer();
    app.UseStaticFiles();

    app.UseRouting();

    app.UseEndpoints(endpoints =>
    {
        endpoints.MapBlazorHub();
        endpoints.MapFallbackToPage("/_Host");
    });
}
```

This project is available on [GitHub][5]{:target="_blank"}.

[1]: https://sass-lang.com/
[2]: https://github.com/ligershark/WebOptimizer
[3]: https://www.nuget.org/packages/LigerShark.WebOptimizer.Core/
[4]: https://www.nuget.org/packages/LigerShark.WebOptimizer.Sass/
[5]: https://github.com/raaaimund/BlazorStyling/tree/blazor-components-scss-weboptimizer
