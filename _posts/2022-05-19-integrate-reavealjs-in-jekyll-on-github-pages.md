---
layout: post
title: How to integrate reveal.js in Jekyll on GitHub pages
date: 2022-05-19 02:30
author: Raimund Rittnauer
description: A simple tutorial on how to integrate reveal.js in Jekyll on GitHub pages
categories: tech
comments: true
tags:
  - revealjs
  - slides
  - github
  - jekyll
---

[reveal.js](https://revealjs.com/){:target="_blank"} is a really simple open source HTML framework for creating stunning presentations. For showing your slides, you only need access to the internet and a web browser. That's it. It also has support for [Markdown](https://revealjs.com/markdown/){:target="_blank"}, so it is perfect for integrating in Jekyll on GitHub pages. The integration is also really straightforward and easy.

The only things you have to do is

1. create a new layout file
2. check the latest version of their [index.html](https://github.com/hakimel/reveal.js/blob/master/index.html){:target="_blank"} file and modify your layout file accordingly
3. grab all needed .css and .js files from their [GitHub repository](https://github.com/hakimel/reveal.js){:target="_blank"} and put them in your assets folder
4. create a new .md file and set the __layout__ to your new layout
5. start creating stunning presentations

## Create a new layout file

I created a new layout file called __slide.html__ and put it in my ___layout__ folder.

## Modify your layout file

Head over to their [GitHub repository](https://github.com/hakimel/reveal.js){:target="_blank"}, check the latest [index.html](https://github.com/hakimel/reveal.js/blob/master/index.html){:target="_blank"} file and modify your layout file accordingly. At the time writing this post i modified my layout file like this:

```html
{% raw %}
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta
      name="viewport"
      content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no"
    />

    {% seo %}

    <link rel="stylesheet" href="{{ "/assets/reveal.js/dist/reset.css" | prepend: site.baseurl }}"/>
    <link rel="stylesheet" href="{{ "/assets/reveal.js/dist/reveal.css" | prepend: site.baseurl }}"/>
    <link rel="stylesheet" href="{{ "/assets/reveal.js/dist/theme/black.css" | prepend: site.baseurl }}"/>
    <link rel="stylesheet" href="{{ "/assets/reveal.js/plugin/highlight/monokai.css" | prepend: site.baseurl }}"/>
  </head>
  <body>
    <div class="reveal">
      <div class="slides">
        {{ content }}
      </div>
    </div>

    <script src="{{ "/assets/reveal.js/dist/reveal.js" | prepend: site.baseurl }}"></script>
    <script src="{{ "/assets/reveal.js/plugin/notes/notes.js" | prepend: site.baseurl }}"></script>
    <script src="{{ "/assets/reveal.js/plugin/markdown/markdown.js" | prepend: site.baseurl }}"></script>
    <script src="{{ "/assets/reveal.js/plugin/highlight/highlight.js" | prepend: site.baseurl }}"></script>

    <script>
      // More info about initialization & config:
      // - https://revealjs.com/initialization/
      // - https://revealjs.com/config/
      Reveal.initialize({
        hash: true,

        // Learn about plugins: https://revealjs.com/plugins/
        plugins: [RevealMarkdown, RevealHighlight, RevealNotes],
      });
    </script>
  </body>
</html>
{% endraw %}
```

## Get the missing files

After that, download all the .css and .js files that are referenced in the new layout file and put them in a new folder in your assets folder. In my assets folder I created a new folder __reveal.js__ and placed the folders __dist__ and __plugin__ from the [GitHub repository](https://github.com/hakimel/reveal.js){:target="_blank"} inside.

## Create your first slide(s)

Now you are ready to create a new .md file with the content of your presentation. Just do not forget to set the __type__ to __slide__ if you have chosen the name __slide.html__ for your layout file. Here is an example .md file:

{% raw %}
```html
---
layout: slide
title: Slides for a git and GitHub workshop
date: 2022-05-10 02:30
author: Raimund Rittnauer
description: Some slides for a git and GitHub workshop using reveal.js
categories: education
comments: true
tags:
  - education
  - workshop
  - slides
---

<section data-markdown>
    <textarea data-template>
        # First
        slide
        ---
        <!-- .slide: data-background-image="/assets/img/2022-05-11-git-github-workshop/mangotime2.jpg" -->
        ## A slide with a background image
        ---
        ## Third
        - slide with
        - some
        - bullet points
        ---
    </textarea>
</section>
```
{% endraw %}

## Have fun with reveal.js

With everything set up, you can use [reveal.js](https://revealjs.com/){:target="_blank"} to create awesome, stunning, and accessible presentations.