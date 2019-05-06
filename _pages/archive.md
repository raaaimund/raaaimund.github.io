---
layout: page
title: archive
permalink: /archive/
description: Collection of all posts.
---

<ul class="post-list">
    {% for post in site.posts %}
    <li>
        <a href="{{ post.url | prepend: site.baseurl }}">{{ post.title }}</a>
        <p class="post-meta">{{ post.date | date: '%B %-d, %Y — %H:%M' }}</p>
    </li>
    {% endfor %}
</ul>